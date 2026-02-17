from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
import os
from datetime import timedelta

auth_bp = Blueprint('auth', __name__)

# Usuarios para pruebas (usando credenciales estándar del proyecto)
USERS = {
    'admin': {
        'password': 'admin123',
        'nombre': 'Administrador',
        'email': 'admin@centrodiagnostico.com',
        'rol': 'admin'
    },
    'doctor': {
        'password': 'doctor123',
        'nombre': 'Doctor',
        'email': 'doctor@centrodiagnostico.com',
        'rol': 'medico'
    },
    'laboratorio': {
        'password': 'lab123',
        'nombre': 'Laboratorista',
        'email': 'lab@centrodiagnostico.com',
        'rol': 'laboratorio'
    }
}

@auth_bp.route('/login', methods=['POST'])
def login():
    """Login endpoint"""
    data = request.get_json()
    
    if not data or not data.get('username') or not data.get('password'):
        return jsonify({'error': 'Username y password requeridos'}), 400
    
    user = USERS.get(data['username'])
    
    if not user or user['password'] != data['password']:
        return jsonify({'error': 'Credenciales inválidas'}), 401
    
    # Crear tokens
    access_token = create_access_token(
        identity=data['username'],
        expires_delta=timedelta(hours=8)
    )
    refresh_token = create_refresh_token(identity=data['username'])
    
    return jsonify({
        'success': True,
        'access_token': access_token,
        'refresh_token': refresh_token,
        'usuario': {
            'username': data['username'],
            'nombre': user['nombre'],
            'email': user['email'],
            'rol': user['rol']
        }
    }), 200

@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """Refresh token endpoint"""
    identity = get_jwt_identity()
    access_token = create_access_token(
        identity=identity,
        expires_delta=timedelta(hours=8)
    )
    
    return jsonify({'access_token': access_token}), 200

@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    """Logout endpoint"""
    return jsonify({'message': 'Logged out successfully'}), 200

@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def me():
    """Get current user info"""
    identity = get_jwt_identity()
    user = USERS.get(identity)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify({
        'username': identity,
        'nombre': user['nombre'],
        'email': user['email'],
        'rol': user['rol']
    }), 200
