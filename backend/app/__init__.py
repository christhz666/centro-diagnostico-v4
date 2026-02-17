from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()

def create_app(config_name='development'):
    from config import config
    
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    # Inicializar extensiones
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    CORS(app)
    
    # Crear directorios
    import os
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    os.makedirs(app.config['RESULTADOS_FOLDER'], exist_ok=True)
    os.makedirs(app.config['TEMP_FOLDER'], exist_ok=True)
    
    # Registrar blueprints
    try:
        from app.routes.auth import auth_bp
        app.register_blueprint(auth_bp, url_prefix='/api/auth')
    except Exception as e:
        print(f"? No se pudo cargar auth: {e}")
    
    # Health check
    @app.route('/api/health', methods=['GET'])
    def health():
        from flask import jsonify
        return jsonify({
            'status': 'ok',
            'message': 'Centro Diagnóstico API',
            'environment': app.config.get('FLASK_ENV', 'production')
        }), 200
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(e):
        from flask import jsonify
        return jsonify({'error': 'Endpoint no encontrado'}), 404
    
    @app.errorhandler(500)
    def internal_error(e):
        from flask import jsonify
        return jsonify({'error': 'Error interno del servidor'}), 500
    
    return app
