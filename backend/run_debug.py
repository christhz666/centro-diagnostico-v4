import os
from dotenv import load_dotenv

load_dotenv()

from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token
from datetime import timedelta

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret')
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'dev-jwt')

CORS(app)
jwt = JWTManager(app)

# Usuarios de prueba
USERS = {
    'admin': {'password': 'admin123', 'nombre': 'Administrador', 'email': 'admin@centro.com'},
    'doctor': {'password': 'doctor123', 'nombre': 'Doctor', 'email': 'doctor@centro.com'},
    'lab': {'password': 'lab123', 'nombre': 'Laboratorio', 'email': 'lab@centro.com'}
}

@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'message': 'API funcionando', 'environment': 'production'}), 200

@app.route('/api/auth/login', methods=['POST'])
def login():
    from flask import request
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        return jsonify({'error': 'Username y password requeridos'}), 400
    
    user = USERS.get(username)
    if not user or user['password'] != password:
        return jsonify({'error': 'Credenciales inválidas'}), 401
    
    access_token = create_access_token(identity=username, expires_delta=timedelta(hours=8))
    
    return jsonify({
        'success': True,
        'access_token': access_token,
        'usuario': {'username': username, 'nombre': user['nombre'], 'email': user['email']}
    }), 200

@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Endpoint no encontrado'}), 404

@app.errorhandler(500)
def internal_error(e):
    return jsonify({'error': 'Error interno'}), 500

if __name__ == '__main__':
    print("? Iniciando Centro Diagnóstico API (DEBUG MODE)")
    print("? Usuarios disponibles: admin, doctor, lab")
    print("? Password: admin123, doctor123, lab123")
    app.run(debug=True, host='0.0.0.0', port=5000)
