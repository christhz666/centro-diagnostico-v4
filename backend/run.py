import os
from dotenv import load_dotenv

load_dotenv()

def create_app(config_name=None):
    from flask import Flask
    from flask_cors import CORS
    from config import config
    import logging
    from logging.handlers import RotatingFileHandler
    
    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'production')
    
    app = Flask(__name__)
    app.json.ensure_ascii = False
    app.config.from_object(config[config_name])
    
    # =====================
    # INICIALIZAR EXTENSIONES
    # =====================
    from app import db, migrate, jwt
    
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    
    # =====================
    # CORS
    # =====================
    allowed_origins = [
        'http://localhost:3000',
        'http://127.0.0.1:3000',
        'http://localhost:5000',
        'http://127.0.0.1:5000',
    ]
    CORS(app, origins=allowed_origins, supports_credentials=True)
    
    # =====================
    # SEGURIDAD
    # =====================
    @app.after_request
    def add_security_headers(response):
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'SAMEORIGIN'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        return response
    
    # =====================
    # CREAR DIRECTORIOS
    # =====================
    os.makedirs(app.config.get('UPLOAD_FOLDER', './uploads'), exist_ok=True)
    os.makedirs(app.config.get('RESULTADOS_FOLDER', './uploads/resultados'), exist_ok=True)
    os.makedirs(app.config.get('TEMP_FOLDER', './uploads/temp'), exist_ok=True)
    
    # =====================
    # REGISTRAR BLUEPRINTS
    # =====================
    try:
        from app.routes import auth_bp
        app.register_blueprint(auth_bp, url_prefix='/api/auth')
    except:
        print("? Módulo auth no disponible")
    
    # =====================
    # LOGGING
    # =====================
    if not app.debug:
        os.makedirs('logs', exist_ok=True)
        file_handler = RotatingFileHandler('logs/app.log', maxBytes=10000000, backupCount=5)
        file_handler.setFormatter(logging.Formatter(
            '%(asctime)s %(levelname)s: %(message)s'
        ))
        app.logger.addHandler(file_handler)
        app.logger.setLevel(logging.INFO)
    
    # =====================
    # HEALTH CHECK
    # =====================
    @app.route('/api/health', methods=['GET'])
    def health():
        from flask import jsonify
        return jsonify({
            'status': 'ok',
            'message': 'Centro Diagnóstico API running',
            'environment': os.getenv('FLASK_ENV', 'production')
        }), 200
    
    # =====================
    # ERROR HANDLERS
    # =====================
    @app.errorhandler(404)
    def not_found(error):
        from flask import jsonify
        return jsonify({'error': 'Endpoint no encontrado'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        from flask import jsonify
        db.session.rollback()
        return jsonify({'error': 'Error interno del servidor'}), 500
    
    return app

if __name__ == '__main__':
    import sys
    env = sys.argv[1] if len(sys.argv) > 1 else 'development'
    app = create_app(env)
    
    if env == 'development':
        app.run(debug=True, host='0.0.0.0', port=5000)
    else:
        print("Usa gunicorn para producción")
        print("gunicorn -w 4 -b 0.0.0.0:5000 run:create_app")
