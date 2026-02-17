import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaHeartbeat, FaEye, FaPlus } from 'react-icons/fa';

function Sonografias() {
  const [sonografias, setSonografias] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    cargarSonografias();
  }, []);

  const cargarSonografias = async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get('/api/sonografias/', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setSonografias(res.data);
      setLoading(false);
    } catch (err) {
      console.error(err);
      setLoading(false);
    }
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <h2 className="page-title">
          <span className="page-title-icon"><FaHeartbeat /></span>
          Sonografías
        </h2>
        <button className="btn btn-primary"><FaPlus /> Nueva Sonografía</button>
      </div>

      {loading ? <div className="loading-spinner"><div className="spinner"></div></div> : (
        <div className="card">
          <div className="card-body">
            {sonografias.length === 0 ? (
              <p className="text-muted">No hay sonografías registradas</p>
            ) : (
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Paciente</th>
                    <th>Tipo</th>
                    <th>Estado</th>
                    <th>Fecha</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {sonografias.map(s => (
                    <tr key={s.id}>
                      <td>{s.paciente}</td>
                      <td>{s.tipo_estudio}</td>
                      <td><span className={`badge badge-${s.estado}`}>{s.estado}</span></td>
                      <td>{new Date(s.fecha_estudio).toLocaleDateString()}</td>
                      <td><button className="btn btn-sm btn-outline"><FaEye /></button></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export default Sonografias;
