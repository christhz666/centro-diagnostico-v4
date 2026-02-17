#!/bin/bash

cd ~/centro-diagnostico/backend

# Matar procesos anteriores
pkill -9 -f "node.*server.js" 2>/dev/null

# Esperar un momento
sleep 2

# Iniciar servidor
nohup node server.js > logs/backend.log 2>&1 &

# Esperar que inicie
sleep 3

# Mostrar estado
echo "========== SERVIDOR INICIADO =========="
echo "PID: $(pgrep -f 'node.*server.js')"
echo ""
echo "Últimos logs:"
tail -20 logs/backend.log
echo ""
echo "Para ver logs en tiempo real:"
echo "  tail -f ~/centro-diagnostico/backend/logs/backend.log"
