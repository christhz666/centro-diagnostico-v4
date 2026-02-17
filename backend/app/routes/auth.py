from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, create_refresh_token,
    jwt_required, get_jwt_identity
)
from werkzeug.security import check_password_hash, generate_password_hash
from app import db
from app.models import Usuario
from app.utils.validators import sanitize_string
from datetime import datetime
import logging
import bcrypt

bp = Blueprint('auth', __name__)
logger = logging.getLogger(__name__)


def verify_password(password_hash, password):
    """Verifica contraseña soportando scrypt y bcrypt"""
    try:
        # Si es scrypt (werkzeug)
        if password_hash.startswith('scrypt:'):
            return check_password_hash(password_hash, password)
        
        # Si es bcrypt
        elif password_hash.startswith('$2b$') or password_hash.startswith('$2a$'):
            return bcrypt.checkpw(password.encode('utf-8'), password_hash.encode('utf-8'))
        
        # Por defecto, intentar con werkzeug
        else:
            return check_password_hash(password_hash, password)
    except Exception as e:
        logger.error(f'Error verificando password: {e}')
        return False


@bp.route('/login', methods=['POST'])
def login():
    try:
        datos = request.get_json()
        if not datos:
            return jsonify({'error': 'Datos requeridos'}), 400

        # Aceptar tanto 'username' como 'email' del frontend
        username_or_email = sanitize_string(
            datos.get('username') or datos.get('email', ''), 
            max_length=100
        )
        password = datos.get('password', '')

        if not username_or_email or not password:
            return jsonify({'error': 'Usuario/Email y contraseña requeridos'}), 400

        if len(password) > 128:
            return jsonify({'error': 'Contraseña demasiado larga'}), 400

        # Buscar usuario por USERNAME o EMAIL
        usuario = Usuario.query.filter(
            (Usuario.username == username_or_email) | 
            (Usuario.email == username_or_email)
        ).first()

        # Timing attack prevention
        if not usuario or not usuario.activo:
            dummy = generate_password_hash('dummy')
            check_password_hash(dummy, 'dummy')
            logger.warning(f'Login fallido para: {username_or_email} desde IP: {request.headers.get("X-Real-IP", request.remote_addr)}')
            return jsonify({'error': 'Credenciales inválidas'}), 401

        # Verificar password con soporte para scrypt y bcrypt
        if verify_password(usuario.password_hash, password):
            usuario.ultimo_acceso = datetime.utcnow()
            db.session.commit()

            identity = str(usuario.id)
            access_token = create_access_token(identity=identity)
            refresh_token = create_refresh_token(identity=identity)

            logger.info(f'Login exitoso: {usuario.username} ({usuario.email}) - Hash: {usuario.password_hash[:10]}...')

            return jsonify({
                'access_token': access_token,
                'refresh_token': refresh_token,
                'usuario': usuario.to_dict()
            })

        logger.warning(f'Password incorrecto para: {username_or_email} desde IP: {request.headers.get("X-Real-IP", request.remote_addr)}')
        return jsonify({'error': 'Credenciales inválidas'}), 401
        
    except Exception as e:
        logger.error(f'Error en login: {str(e)}')
        return jsonify({'error': 'Error interno del servidor'}), 500


@bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    current_user_id = get_jwt_identity()
    access_token = create_access_token(identity=current_user_id)
    return jsonify({'access_token': access_token})


@bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    current_user_id = get_jwt_identity()
    usuario = Usuario.query.get(int(current_user_id))
    if not usuario:
        return jsonify({'error': 'Usuario no encontrado'}), 404
    return jsonify(usuario.to_dict())


@bp.route('/cambiar-password', methods=['POST'])
@jwt_required()
def cambiar_password():
    try:
        current_user_id = get_jwt_identity()
        usuario = Usuario.query.get(int(current_user_id))
        
        if not usuario:
            return jsonify({'error': 'Usuario no encontrado'}), 404
            
        datos = request.get_json()
        password_actual = datos.get('password_actual')
        password_nueva = datos.get('password_nueva')
        
        if not password_actual or not password_nueva:
            return jsonify({'error': 'Contraseñas requeridas'}), 400
            
        if not verify_password(usuario.password_hash, password_actual):
            return jsonify({'error': 'Contraseña actual incorrecta'}), 401
            
        # Usar scrypt (werkzeug) para consistencia
        usuario.password_hash = generate_password_hash(password_nueva)
        db.session.commit()
        
        return jsonify({'message': 'Contraseña actualizada exitosamente'})
    except Exception as e:
        logger.error(f'Error cambiando password: {str(e)}')
        return jsonify({'error': 'Error interno del servidor'}), 500
