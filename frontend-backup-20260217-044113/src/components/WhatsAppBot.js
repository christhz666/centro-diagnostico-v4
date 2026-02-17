import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaWhatsapp, FaPaperPlane } from 'react-icons/fa';

function WhatsAppBot() {
  const [mensajes, setMensajes] = useState([]);
  const [telefono, setTelefono] = useState('');
  const [mensaje, setMensaje] = useState('');

  useEffect(() => {
    cargarHistorial();
  }, []);

  const cargarHistorial = async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get('/api/whatsapp/historial', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setMensajes(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  const enviarMensaje = async (e) => {
    e.preventDefault();
    try {
      const token = localStorage.getItem('token');
      await axios.post('/api/whatsapp/enviar', { telefono, mensaje }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      alert('Mensaje enviado');
      setTelefono('');
      setMensaje('');
      cargarHistorial();
    } catch (err) {
      alert('Error al enviar');
    }
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <h2 className="page-title">
          <span className="page-title-icon"><FaWhatsapp /></span>
          WhatsApp Bot
        </h2>
      </div>

      <div className="content-grid">
        <div className="card">
          <div className="card-header"><h3>Enviar Mensaje</h3></div>
          <div className="card-body">
            <form onSubmit={enviarMensaje}>
              <div className="form-group">
                <label>Teléfono</label>
                <input type="text" className="form-control" value={telefono} 
                  onChange={e => setTelefono(e.target.value)} placeholder="+18095551234" required />
              </div>
              <div className="form-group">
                <label>Mensaje</label>
                <textarea className="form-control" rows="4" value={mensaje}
                  onChange={e => setMensaje(e.target.value)} required></textarea>
              </div>
              <button type="submit" className="btn btn-primary">
                <FaPaperPlane /> Enviar
              </button>
            </form>
          </div>
        </div>

        <div className="card">
          <div className="card-header"><h3>Historial</h3></div>
          <div className="card-body">
            {mensajes.map(m => (
              <div key={m.id} style={{marginBottom: '10px', padding: '10px', background: '#f5f5f5', borderRadius: '5px'}}>
                <strong>{m.telefono}</strong>
                <p style={{margin: '5px 0'}}>{m.mensaje}</p>
                <small className="text-muted">{new Date(m.fecha).toLocaleString()}</small>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

export default WhatsAppBot;
