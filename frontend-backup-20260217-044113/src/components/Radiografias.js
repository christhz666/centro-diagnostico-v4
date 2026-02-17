import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaXRay, FaEye, FaUpload } from 'react-icons/fa';

function Radiografias() {
  const [radiografias, setRadiografias] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    cargarRadiografias();
  }, []);

  const cargarRadiografias = async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get('/api/radiografias/', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setRadiografias(res.data);
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
          <span className="page-title-icon"><FaXRay /></span>
          Radiografías
        </h2>
        <button className="btn btn-primary"><FaUpload /> Subir Radiografía</button>
      </div>

      {loading ? <div className="loading-spinner"><div className="spinner"></div></div> : (
        <div className="card">
          <div className="card-body">
            {radiografias.length === 0 ? (
              <p className="text-muted">No hay radiografías registradas</p>
            ) : (
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Paciente</th>
                    <th>Tipo</th>
                    <th>Región</th>
                    <th>Estado</th>
                    <th>Fecha</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {radiografias.map(r => (
                    <tr key={r.id}>
                      <td>{r.paciente}</td>
                      <td>{r.tipo_estudio}</td>
                      <td>{r.region_anatomica}</td>
                      <td><span className={`badge badge-${r.estado}`}>{r.estado}</span></td>
                      <td>{new Date(r.fecha_toma).toLocaleDateString()}</td>
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

export default Radiografias;
