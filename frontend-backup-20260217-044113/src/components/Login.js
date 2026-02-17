import React, { useState } from 'react';
import { FaHeartbeat, FaEnvelope, FaLock, FaSignInAlt, FaSpinner, FaEye, FaEyeSlash } from 'react-icons/fa';

const Login = ({ onLogin }) => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            const response = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    username: email,  // ? Cambiar 'email' a 'username'
                    password 
                })
            });

            const data = await response.json();

            // ? El backend responde con access_token y usuario
            if (response.ok && data.access_token && data.usuario) {
                // Guardar token y usuario
                localStorage.setItem('token', data.access_token);
                localStorage.setItem('user', JSON.stringify(data.usuario));
                
                // Llamar onLogin con los datos correctos
                onLogin(data.access_token, data.usuario);
            } else {
                // Mostrar error del backend
                setError(data.error || 'Credenciales inválidas');
            }
        } catch (err) {
            console.error('Error de login:', err);
            setError('Error de conexión con el servidor');
        } finally {
            setLoading(false);
        }
    };

    const styles = {
        container: {
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #0f4c75 0%, #1b262c 50%, #3282b8 100%)',
        },
        card: {
            background: 'rgba(255,255,255,0.95)',
            borderRadius: '20px',
            padding: '40px',
            width: '100%',
            maxWidth: '400px',
            margin: '20px',
            boxShadow: '0 20px 60px rgba(0,0,0,0.3)',
        },
        logoSection: { textAlign: 'center', marginBottom: '30px' },
        logoCircle: {
            width: '80px',
            height: '80px',
            borderRadius: '50%',
            background: 'linear-gradient(135deg, #e74c3c, #c0392b)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            margin: '0 auto 15px',
        },
        title: { fontSize: '28px', fontWeight: 'bold', color: '#1b262c', margin: 0 },
        subtitle: { fontSize: '14px', color: '#666', margin: '5px 0 0' },
        form: { display: 'flex', flexDirection: 'column', gap: '15px' },
        errorBox: {
            background: '#fee',
            color: '#c0392b',
            padding: '12px',
            borderRadius: '10px',
            fontSize: '14px',
            border: '1px solid #fcc',
        },
        inputGroup: { position: 'relative', display: 'flex', alignItems: 'center' },
        inputIcon: { position: 'absolute', left: '15px', color: '#999', fontSize: '16px' },
        input: {
            width: '100%',
            padding: '14px 45px',
            borderRadius: '10px',
            border: '2px solid #e0e0e0',
            fontSize: '15px',
            outline: 'none',
            boxSizing: 'border-box',
            transition: 'border 0.3s',
        },
        eyeButton: {
            position: 'absolute',
            right: '15px',
            background: 'none',
            border: 'none',
            color: '#999',
            cursor: 'pointer',
            fontSize: '16px',
        },
        button: {
            padding: '14px',
            borderRadius: '10px',
            border: 'none',
            background: 'linear-gradient(135deg, #e74c3c, #c0392b)',
            color: 'white',
            fontSize: '16px',
            fontWeight: 'bold',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginTop: '10px',
            transition: 'transform 0.2s',
        },
        demoInfo: {
            marginTop: '25px',
            padding: '15px',
            background: '#f8f9fa',
            borderRadius: '10px',
            borderLeft: '4px solid #3282b8',
        },
        demoTitle: {
            margin: 0,
            fontSize: '13px',
            fontWeight: 'bold',
            color: '#333',
        },
        demoText: {
            margin: '5px 0 0',
            fontSize: '12px',
            fontFamily: 'monospace',
            color: '#666',
        },
    };

    return (
        <div style={styles.container}>
            <div style={styles.card}>
                <div style={styles.logoSection}>
                    <div style={styles.logoCircle}>
                        <FaHeartbeat style={{ fontSize: '36px', color: 'white' }} />
                    </div>
                    <h1 style={styles.title}>Mi Esperanza</h1>
                    <p style={styles.subtitle}>Centro Diagnóstico</p>
                </div>

                <form onSubmit={handleSubmit} style={styles.form}>
                    {error && (
                        <div style={styles.errorBox}>
                            <strong>?? Error:</strong> {error}
                        </div>
                    )}

                    <div style={styles.inputGroup}>
                        <FaEnvelope style={styles.inputIcon} />
                        <input
                            type="text"
                            placeholder="Email o Usuario"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                            style={styles.input}
                            disabled={loading}
                            autoComplete="username"
                        />
                    </div>

                    <div style={styles.inputGroup}>
                        <FaLock style={styles.inputIcon} />
                        <input
                            type={showPassword ? 'text' : 'password'}
                            placeholder="Contraseña"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                            style={styles.input}
                            disabled={loading}
                            autoComplete="current-password"
                        />
                        <button 
                            type="button" 
                            onClick={() => setShowPassword(!showPassword)} 
                            style={styles.eyeButton}
                            tabIndex="-1"
                        >
                            {showPassword ? <FaEyeSlash /> : <FaEye />}
                        </button>
                    </div>

                    <button 
                        type="submit" 
                        style={{
                            ...styles.button, 
                            opacity: loading ? 0.7 : 1,
                            cursor: loading ? 'not-allowed' : 'pointer'
                        }} 
                        disabled={loading}
                    >
                        {loading ? (
                            <>
                                <FaSpinner style={{marginRight: 8, animation: 'spin 1s linear infinite'}} /> 
                                Iniciando sesión...
                            </>
                        ) : (
                            <>
                                <FaSignInAlt style={{marginRight: 8}} /> 
                                Iniciar Sesión
                            </>
                        )}
                    </button>
                </form>

                <div style={styles.demoInfo}>
                    <p style={styles.demoTitle}>? Credenciales de prueba:</p>
                    <p style={styles.demoText}>?? admin@miesperanza.com</p>
                    <p style={styles.demoText}>?? Admin123!</p>
                </div>
            </div>
            <style>
                {`
                    @keyframes spin {
                        from { transform: rotate(0deg); }
                        to { transform: rotate(360deg); }
                    }
                    input:focus {
                        border-color: #3282b8 !important;
                    }
                `}
            </style>
        </div>
    );
};

export default Login;
