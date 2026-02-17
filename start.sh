#!/bin/bash

echo ""
echo "+---------------------------------------------------+"
echo "¦  ?? Centro Diagnóstico Mi Esperanza              ¦"
echo "¦  ?? Script de Instalación y Arranque             ¦"
echo "+---------------------------------------------------+"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ========== VERIFICAR MONGODB ==========
echo -e "${BLUE}[1/6]${NC} Verificando MongoDB..."
if mongosh --eval "db.version()" > /dev/null 2>&1; then
    echo -e "${GREEN}  ? MongoDB está corriendo${NC}"
else
    echo -e "${YELLOW}  ?? Intentando iniciar MongoDB...${NC}"
    sudo systemctl start mongod 2>/dev/null || sudo service mongod start 2>/dev/null
    sleep 2
    if mongosh --eval "db.version()" > /dev/null 2>&1; then
        echo -e "${GREEN}  ? MongoDB iniciado${NC}"
    else
        echo -e "${RED}  ? No se pudo iniciar MongoDB${NC}"
        echo "  Instalar: sudo yum install -y mongodb-org"
        exit 1
    fi
fi

# ========== INSTALAR DEPENDENCIAS BACKEND ==========
echo -e "${BLUE}[2/6]${NC} Instalando dependencias del backend..."
cd ~/centro-diagnostico/backend
npm install --production 2>&1 | tail -1
echo -e "${GREEN}  ? Dependencias del backend instaladas${NC}"

# ========== EJECUTAR SEED ==========
echo -e "${BLUE}[3/6]${NC} Ejecutando seed (datos iniciales)..."
node utils/seed.js 2>&1
echo -e "${GREEN}  ? Seed completado${NC}"

# ========== MATAR PROCESOS ANTERIORES ==========
echo -e "${BLUE}[4/6]${NC} Limpiando procesos anteriores..."
pkill -f "node server.js" 2>/dev/null
pkill -f "react-scripts" 2>/dev/null
sleep 2
echo -e "${GREEN}  ? Procesos limpiados${NC}"

# ========== INICIAR BACKEND ==========
echo -e "${BLUE}[5/6]${NC} Iniciando Backend (API)..."
cd ~/centro-diagnostico/backend
nohup node server.js > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
sleep 3

# Verificar que el backend está corriendo
if curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}  ? Backend corriendo en puerto 5000 (PID: $BACKEND_PID)${NC}"
else
    echo -e "${RED}  ? Error al iniciar el backend${NC}"
    echo "  Ver log: cat ~/centro-diagnostico/logs/backend.log"
fi

# ========== INICIAR FRONTEND ==========
echo -e "${BLUE}[6/6]${NC} Iniciando Frontend (React)..."
cd ~/centro-diagnostico/frontend
nohup npm start > ../logs/frontend.log 2>&1 &
FRONTEND_PID=$!
echo -e "${GREEN}  ? Frontend iniciando en puerto 3000 (PID: $FRONTEND_PID)${NC}"
echo "  (Puede tomar 30-60 segundos en compilar)"

# ========== RESUMEN ==========
echo ""
echo "+-------------------------------------------------------+"
echo "¦  ?? ¡TODO LISTO!                                     ¦"
echo "¦                                                       ¦"
echo "¦  ?? Frontend: http://192.9.135.84:3000               ¦"
echo "¦  ?? API:      http://192.9.135.84:5000/api           ¦"
echo "¦  ??  Health:   http://192.9.135.84:5000/api/health   ¦"
echo "¦                                                       ¦"
echo "¦  Credenciales:                                        ¦"
echo "¦  ?? Admin:  admin@miesperanza.com / Admin123!        ¦"
echo "¦  ?? Médico: doctor@miesperanza.com / Doctor123!      ¦"
echo "¦  ?? Recep:  recepcion@miesperanza.com / Recepcion123!¦"
echo "¦  ?? Lab:    lab@miesperanza.com / Lab123!            ¦"
echo "¦                                                       ¦"
echo "¦  Logs:                                                ¦"
echo "¦  Backend:  tail -f ~/centro-diagnostico/logs/backend.log  ¦"
echo "¦  Frontend: tail -f ~/centro-diagnostico/logs/frontend.log ¦"
echo "+-----------------------------------------------------------+"
echo ""
