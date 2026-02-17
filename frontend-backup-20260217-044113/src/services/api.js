const API_URL = '/api';

class ApiService {
    getToken() {
        return localStorage.getItem('token');
    }

    getHeaders() {
        const headers = { 'Content-Type': 'application/json' };
        const token = this.getToken();
        if (token) {
            headers['Authorization'] = 'Bearer ' + token;
        }
        return headers;
    }

    async request(endpoint, options = {}) {
        const url = API_URL + endpoint;
        const config = { headers: this.getHeaders(), ...options };

        const response = await fetch(url, config);
        const data = await response.json();

        if (response.status === 401 && !window.location.pathname.includes('login')) {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            window.location.href = '/login';
            throw new Error('Sesion expirada');
        }

        if (!response.ok) {
            throw new Error(data.message || 'Error ' + response.status);
        }

        return data;
    }

    // ============ AUTH ============
    async login(email, password) {
        const data = await this.request('/auth/login', {
            method: 'POST',
            body: JSON.stringify({ email, password })
        });
        if (data.success && data.token) {
            localStorage.setItem('token', data.token);
            localStorage.setItem('user', JSON.stringify(data.user));
        }
        return data;
    }

    logout() {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.location.href = '/login';
    }

    isAuthenticated() {
        return !!this.getToken();
    }

    getUser() {
        const user = localStorage.getItem('user');
        return user ? JSON.parse(user) : null;
    }

    async getMe() { 
        return this.request('/auth/me'); 
    }

    // ============ DASHBOARD ============
    async getDashboardStats() { 
        return this.request('/dashboard/stats'); 
    }
    
    async getCitasHoy() { 
        return this.request('/citas/hoy'); 
    }
    
    async getCitasGrafica() { 
        return this.request('/dashboard/citas-grafica'); 
    }
    
    async getTopEstudios() { 
        return this.request('/dashboard/top-estudios'); 
    }

    // ============ PACIENTES ============
    async getPacientes(params = {}) { 
        const query = new URLSearchParams(params).toString();
        return this.request('/pacientes?' + query); 
    }
    
    async getPaciente(id) { 
        return this.request('/pacientes/' + id); 
    }
    
    async createPaciente(data) { 
        return this.request('/pacientes', { 
            method: 'POST', 
            body: JSON.stringify(data) 
        }); 
    }
    
    async updatePaciente(id, data) { 
        return this.request('/pacientes/' + id, { 
            method: 'PUT', 
            body: JSON.stringify(data) 
        }); 
    }

    // ============ CITAS ============
    async getCitas(params = {}) { 
        const query = new URLSearchParams(params).toString();
        return this.request('/citas?' + query); 
    }
    
    async getCita(id) { 
        return this.request('/citas/' + id); 
    }
    
    async createCita(data) { 
        return this.request('/citas', { 
            method: 'POST', 
            body: JSON.stringify(data) 
        }); 
    }
    
    async updateCita(id, data) { 
        return this.request('/citas/' + id, { 
            method: 'PUT', 
            body: JSON.stringify(data) 
        }); 
    }

    // ============ ESTUDIOS ============
    async getEstudios(params = {}) { 
        const query = new URLSearchParams(params).toString();
        return this.request('/estudios?' + query); 
    }
    
    async getEstudio(id) { 
        return this.request('/estudios/' + id); 
    }
    
    async createEstudio(data) { 
        return this.request('/estudios', { 
            method: 'POST', 
            body: JSON.stringify(data) 
        }); 
    }
    
    async updateEstudio(id, data) { 
        return this.request('/estudios/' + id, { 
            method: 'PUT', 
            body: JSON.stringify(data) 
        }); 
    }
    
    async deleteEstudio(id) { 
        return this.request('/estudios/' + id, { 
            method: 'DELETE' 
        }); 
    }
    
    async getCategorias() { 
        return this.request('/estudios/categorias'); 
    }

    // ============ RESULTADOS ============
    async getResultados(params = {}) { 
        const query = new URLSearchParams(params).toString();
        return this.request('/resultados?' + query); 
    }
    
    async getResultado(id) { 
        return this.request('/resultados/' + id); 
    }
    
    async createResultado(data) { 
        return this.request('/resultados', { 
            method: 'POST', 
            body: JSON.stringify(data) 
        }); 
    }
    
    async updateResultado(id, data) { 
        return this.request('/resultados/' + id, { 
            method: 'PUT', 
            body: JSON.stringify(data) 
        }); 
    }
    
    async validarResultado(id, data) { 
        return this.request('/resultados/' + id + '/validar', { 
            method: 'PATCH', 
            body: JSON.stringify(data) 
        }); 
    }

    // ============ FACTURAS ============
    async getFacturas(params = {}) { 
        const query = new URLSearchParams(params).toString();
        return this.request('/facturas?' + query); 
    }
    
    async getFactura(id) { 
        return this.request('/facturas/' + id); 
    }
    
    async createFactura(data) { 
        return this.request('/facturas', { 
            method: 'POST', 
            body: JSON.stringify(data) 
        }); 
    }
    
    async anularFactura(id, motivo) { 
        return this.request('/facturas/' + id + '/anular', { 
            method: 'PATCH', 
            body: JSON.stringify({ motivo }) 
        }); 
    }

    // ============ ADMIN ============
    async getUsuarios(params = {}) { 
        const query = new URLSearchParams(params).toString();
        return this.request('/admin/usuarios?' + query); 
    }
    
    async getUsuario(id) { 
        return this.request('/admin/usuarios/' + id); 
    }
    
    async createUsuario(data) { 
        return this.request('/admin/usuarios', { 
            method: 'POST', 
            body: JSON.stringify(data) 
        }); 
    }
    
    async updateUsuario(id, data) { 
        return this.request('/admin/usuarios/' + id, { 
            method: 'PUT', 
            body: JSON.stringify(data) 
        }); 
    }
    
    async toggleUsuario(id) { 
        return this.request('/admin/usuarios/' + id + '/toggle', { 
            method: 'PATCH' 
        }); 
    }
    
    async resetPasswordUsuario(id, newPassword) { 
        return this.request('/admin/usuarios/' + id + '/reset-password', { 
            method: 'PATCH', 
            body: JSON.stringify({ newPassword }) 
        }); 
    }
    
    async getMedicos() { 
        return this.request('/admin/medicos'); 
    }
    
    async getRoles() { 
        return this.request('/admin/roles'); 
    }

    // ============ HEALTH ============
    async healthCheck() { 
        return this.request('/health'); 
    }
}

const api = new ApiService();
export default api;
