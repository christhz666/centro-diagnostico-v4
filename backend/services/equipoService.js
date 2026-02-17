const Equipo = require('../models/Equipo');
const Resultado = require('../models/Resultado');
const EventEmitter = require('events');

class EquipoService extends EventEmitter {
  constructor() {
    super();
    this.conexiones = new Map();
    this.colas = new Map();
  }

  // Iniciar monitoreo de todos los equipos activos
  async iniciarTodos() {
    const equipos = await Equipo.find({ estado: 'activo' });
    console.log(`?? Iniciando ${equipos.length} equipos...`);
    
    for (const equipo of equipos) {
      await this.iniciarEquipo(equipo._id);
    }
  }

  // Iniciar comunicación con un equipo específico
  async iniciarEquipo(equipoId) {
    const equipo = await Equipo.findById(equipoId);
    if (!equipo) throw new Error('Equipo no encontrado');

    console.log(`?? Conectando a ${equipo.nombre} (${equipo.protocolo})...`);

    switch (equipo.protocolo) {
      case 'ASTM':
        return this.iniciarASTM(equipo);
      case 'HL7':
        return this.iniciarHL7(equipo);
      case 'SERIAL':
        return this.iniciarSerial(equipo);
      case 'TCP':
        return this.iniciarTCP(equipo);
      case 'FILE':
        return this.iniciarFile(equipo);
      default:
        throw new Error(`Protocolo ${equipo.protocolo} no soportado`);
    }
  }

  // Protocolo ASTM (Mindray BS-200, BC-6800)
  async iniciarASTM(equipo) {
    console.log(`? ASTM iniciado para ${equipo.nombre}`);
    
    this.conexiones.set(equipo._id.toString(), {
      equipo,
      protocolo: 'ASTM',
      estado: 'conectado',
      procesarDatos: (datos) => this.procesarASTM(equipo, datos)
    });

    return true;
  }

  // Procesar mensaje ASTM
  async procesarASTM(equipo, mensaje) {
    const lineas = mensaje.split('\n');
    let pacienteId = null;
    let resultados = [];

    for (const linea of lineas) {
      const campos = linea.split('|');
      const tipo = campos[0];

      switch (tipo) {
        case 'H':
          console.log('?? Recibiendo transmisión ASTM...');
          break;
          
        case 'P':
          pacienteId = campos[2];
          break;
          
        case 'R':
          const codigoTest = campos[2]?.split('^')[3] || campos[2];
          const valor = campos[3];
          const unidad = campos[4];
          const estado = campos[8];
          
          resultados.push({
            codigoEquipo: codigoTest,
            valor,
            unidad,
            estado: estado === 'N' ? 'normal' : estado === 'H' ? 'alto' : 'bajo'
          });
          break;
      }
    }

    if (resultados.length > 0) {
      await this.guardarResultados(equipo, pacienteId, null, resultados);
    }

    return resultados;
  }

  // Guardar resultados en la base de datos
  async guardarResultados(equipo, pacienteId, ordenId, resultados) {
    try {
      const Paciente = require('../models/Paciente');
      const paciente = await Paciente.findOne({ cedula: pacienteId });

      if (!paciente) {
        console.warn(`?? Paciente no encontrado: ${pacienteId}`);
        this.colas.set(`${equipo._id}-${pacienteId}`, {
          equipo: equipo._id,
          pacienteId,
          resultados,
          fecha: new Date()
        });
        return null;
      }

      const valoresMapeados = resultados.map(r => {
        const mapeo = equipo.mapeoParametros.find(m => m.codigoEquipo === r.codigoEquipo);
        return {
          parametro: mapeo?.nombreParametro || r.codigoEquipo,
          valor: (parseFloat(r.valor) * (mapeo?.factor || 1)).toFixed(mapeo?.decimales || 2),
          unidad: mapeo?.unidad || r.unidad,
          valorReferencia: mapeo?.valorReferencia,
          estado: r.estado
        };
      });

      const resultado = await Resultado.create({
        paciente: paciente._id,
        valores: valoresMapeados,
        equipoOrigen: equipo._id,
        estado: 'pendiente_validacion',
        fechaRecepcion: new Date()
      });

      await Equipo.findByIdAndUpdate(equipo._id, {
        ultimaConexion: new Date(),
        $inc: { 'estadisticas.resultadosRecibidos': 1 },
        'estadisticas.ultimoResultado': new Date()
      });

      this.emit('nuevoResultado', {
        equipo: equipo.nombre,
        paciente: paciente.nombre,
        resultado: resultado._id
      });

      console.log(`? Resultado guardado: ${paciente.nombre}`);
      return resultado;

    } catch (error) {
      console.error('? Error guardando resultado:', error);
      await Equipo.findByIdAndUpdate(equipo._id, {
        ultimoError: error.message,
        $inc: { 'estadisticas.errores': 1 }
      });
      throw error;
    }
  }

  // Detener equipo
  async detenerEquipo(equipoId) {
    const conexion = this.conexiones.get(equipoId.toString());
    if (conexion) {
      this.conexiones.delete(equipoId.toString());
      console.log(`?? Equipo desconectado: ${conexion.equipo.nombre}`);
    }
  }

  // Obtener estado de todos los equipos
  obtenerEstados() {
    const estados = [];
    for (const [id, conexion] of this.conexiones) {
      estados.push({
        id,
        nombre: conexion.equipo.nombre,
        estado: conexion.estado,
        protocolo: conexion.protocolo
      });
    }
    return estados;
  }
}

module.exports = new EquipoService();
