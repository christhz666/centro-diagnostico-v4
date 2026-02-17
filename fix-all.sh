#!/bin/bash
echo ""
echo "========================================="
echo "  ?? ARREGLANDO TODO - Mi Esperanza"
echo "========================================="
echo ""

# ===== 1. Matar TODO =====
echo "[1/6] Limpiando procesos..."
sudo pkill -f gunicorn 2>/dev/null
pkill -f "node server.js" 2>/dev/null
pkill -f "react-scripts" 2>/dev/null
pkill -f "npm start" 2>/dev/null
sleep 3
echo "  ? Procesos limpiados"

# Verificar puerto 5000 libre
if sudo ss -tlnp | grep -q ":5000 "; then
    echo "  ?? Puerto 5000 aún ocupado, matando..."
    sudo fuser -k 5000/tcp 2>/dev/null
    sleep 2
fi

# ===== 2. MongoDB =====
echo "[2/6] Verificando MongoDB..."
if sudo systemctl status mongod > /dev/null 2>&1; then
    sudo systemctl start mongod
    echo "  ? MongoDB corriendo"
else
    echo "  ? MongoDB no instalado. Instalando..."
    
    # Detectar versión de OS
    OS_VERSION=$(cat /etc/os-release | grep VERSION_ID | cut -d'"' -f2 | cut -d'.' -f1)
    echo "  OS Version: $OS_VERSION"
    
    sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo > /dev/null << MONGOREPO
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/${OS_VERSION}/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
MONGOREPO
    
    sudo yum install -y mongodb-org 2>&1 | tail -3
    sudo systemctl start mongod
    sudo systemctl enable mongod
    
    if sudo systemctl is-active mongod > /dev/null 2>&1; then
        echo "  ? MongoDB instalado e iniciado"
    else
        echo "  ? Error instalando MongoDB"
        echo "  Intenta manualmente:"
        echo "  sudo yum install -y mongodb-org"
        exit 1
    fi
fi

# ===== 3. Seed =====
echo "[3/6] Ejecutando seed..."
cd ~/centro-diagnostico/backend
node utils/seed.js 2>&1 | grep -E "?|??|?"

# ===== 4. Backend =====
echo "[4/6] Iniciando Backend..."
cd ~/centro-diagnostico/backend
mkdir -p ~/centro-diagnostico/logs
nohup node server.js > ~/centro-diagnostico/logs/backend.log 2>&1 &
sleep 4

if curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
    echo "  ? Backend corriendo en :5000"
else
    echo "  ? Backend falló:"
    tail -10 ~/centro-diagnostico/logs/backend.log
    exit 1
fi

# ===== 5. Frontend =====
echo "[5/6] Iniciando Frontend..."
cd ~/centro-diagnostico/frontend
nohup npm start > ~/centro-diagnostico/logs/frontend.log 2>&1 &
echo "  ? Compilando React... (30 seg)"
sleep 30

if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "  ? Frontend corriendo en :3000"
else
    echo "  ?? Aún compilando, esperar 30 seg más..."
    sleep 30
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo "  ? Frontend corriendo en :3000"
    else
        echo "  ? Frontend no arranca:"
        tail -20 ~/centro-diagnostico/logs/frontend.log
    fi
fi

# ===== 6. Nginx =====
echo "[6/6] Reiniciando Nginx..."
sudo nginx -t 2>&1 | grep -q "successful" && {
    sudo systemctl restart nginx
    echo "  ? Nginx OK"
} || {
    echo "  ? Error en Nginx config"
    sudo nginx -t
}

# ===== VERIFICACIÓN FINAL =====
echo ""
echo "========================================="
echo "  ?? VERIFICACIÓN FINAL"
echo "========================================="
echo ""
echo -n "  MongoDB:  "; sudo systemctl is-active mongod
echo -n "  Backend:  "; curl -s http://localhost:5000/api/health | python3 -c "import sys,json; print(json.load(sys.stdin).get('message','?'))" 2>/dev/null || echo "? No responde"
echo -n "  Frontend: "; curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:3000 2>/dev/null; echo ""
echo -n "  Nginx:    "; curl -s -o /dev/null -w "HTTP %{http_code}" http://192.9.135.84 2>/dev/null; echo ""

echo ""
echo "========================================="
echo "  ?? http://192.9.135.84"
echo ""
echo "  ?? admin@miesperanza.com / Admin123!"
echo "  ?? doctor@miesperanza.com / Doctor123!"  
echo "  ?? recepcion@miesperanza.com / Recepcion123!"
echo ""
echo "  ?? Ver logs:"
echo "  tail -f ~/centro-diagnostico/logs/backend.log"
echo "  tail -f ~/centro-diagnostico/logs/frontend.log"
echo "========================================="
