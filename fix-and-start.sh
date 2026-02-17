#!/bin/bash

echo ""
echo "+---------------------------------------------------+"
echo "¦  ?? Centro Diagnóstico Mi Esperanza              ¦"
echo "¦  ?? Fix 502 + Arranque Completo                  ¦"
echo "+---------------------------------------------------+"
echo ""

# ===== 1. Matar procesos anteriores =====
echo "[1/7] ?? Limpiando procesos..."
pkill -f "node server.js" 2>/dev/null
pkill -f "react-scripts" 2>/dev/null
pkill -f "npm start" 2>/dev/null
sleep 3
echo "  ? Procesos limpiados"

# ===== 2. MongoDB =====
echo "[2/7] ??? Verificando MongoDB..."
if mongosh --eval "db.version()" > /dev/null 2>&1; then
    echo "  ? MongoDB corriendo"
else
    echo "  ?? Iniciando MongoDB..."
    sudo systemctl start mongod 2>/dev/null
    sleep 2
    if mongosh --eval "db.version()" > /dev/null 2>&1; then
        echo "  ? MongoDB iniciado"
    else
        echo "  ? MongoDB no se pudo iniciar. Verificar instalación."
        exit 1
    fi
fi

# ===== 3. Backend =====
echo "[3/7] ?? Preparando Backend..."
cd ~/centro-diagnostico/backend
npm install --production 2>&1 | tail -1

# ===== 4. Seed =====
echo "[4/7] ?? Ejecutando seed..."
node utils/seed.js 2>&1 | grep -E "?|??|+|¦|+"

# ===== 5. Arrancar Backend =====
echo "[5/7] ?? Iniciando Backend..."
mkdir -p ~/centro-diagnostico/logs
cd ~/centro-diagnostico/backend
nohup node server.js > ~/centro-diagnostico/logs/backend.log 2>&1 &
sleep 4

if curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
    echo "  ? Backend corriendo en :5000"
else
    echo "  ? Backend falló. Log:"
    tail -15 ~/centro-diagnostico/logs/backend.log
    echo ""
    echo "  Arregla el error y vuelve a ejecutar este script"
    exit 1
fi

# ===== 6. Arrancar Frontend =====
echo "[6/7] ?? Iniciando Frontend..."
cd ~/centro-diagnostico/frontend
nohup npm start > ~/centro-diagnostico/logs/frontend.log 2>&1 &
echo "  ? Compilando React (30-60 segundos)..."
sleep 35

if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "  ? Frontend corriendo en :3000"
else
    echo "  ?? Frontend aún compilando... verificar en 30 segundos"
fi

# ===== 7. Nginx =====
echo "[7/7] ?? Reiniciando Nginx..."
sudo nginx -t 2>&1 | grep -q "successful" && {
    sudo systemctl restart nginx
    echo "  ? Nginx reiniciado"
} || {
    echo "  ? Error en configuración de Nginx"
    sudo nginx -t
}

# ===== RESUMEN =====
echo ""
echo "+---------------------------------------------------------+"
echo "¦  ?? ¡SISTEMA INICIADO!                                 ¦"
echo "¦                                                         ¦"
echo "¦  ?? Sitio:    http://192.9.135.84                      ¦"
echo "¦  ?? API:      http://192.9.135.84/api/health           ¦"
echo "¦  ??  React:    http://192.9.135.84:3000 (directo)      ¦"
echo "¦  ?? Express:  http://192.9.135.84:5000/api (directo)   ¦"
echo "¦                                                         ¦"
echo "¦  ?? Admin:    admin@miesperanza.com / Admin123!         ¦"
echo "¦  ?? Doctor:   doctor@miesperanza.com / Doctor123!       ¦"
echo "¦  ?? Recepción: recepcion@miesperanza.com / Recepcion123!¦"
echo "¦                                                         ¦"
echo "¦  ?? Logs:                                               ¦"
echo "¦  tail -f ~/centro-diagnostico/logs/backend.log          ¦"
echo "¦  tail -f ~/centro-diagnostico/logs/frontend.log         ¦"
echo "¦  sudo tail -f /var/log/nginx/centro-diagnostico-error.log¦"
echo "+---------------------------------------------------------+"
echo ""

# Verificación final
echo "?? Verificación final:"
sleep 2
echo -n "  Backend:  "; curl -s http://localhost:5000/api/health | grep -o '"message":"[^"]*"' || echo "? No responde"
echo -n "  Frontend: "; curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 && echo " ?" || echo " ?"
echo -n "  Nginx:    "; curl -s -o /dev/null -w "%{http_code}" http://192.9.135.84 && echo " ?" || echo " ?"
echo ""
