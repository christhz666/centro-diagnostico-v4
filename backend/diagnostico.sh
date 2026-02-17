#!/bin/bash

echo "+---------------------------------------------------------------+"
echo "¦            DIAGNÓSTICO DEL BACKEND                            ¦"
echo "+---------------------------------------------------------------+"
echo ""

cd ~/centro-diagnostico/backend

echo "1??  ARCHIVOS DE RUTAS:"
ls -1 routes/ | grep -E "\.js$"

echo ""
echo "2??  MODELOS:"
ls -1 models/ | grep -E "\.js$"

echo ""
echo "3??  CONTROLADORES:"
ls -1 controllers/ | grep -E "\.js$"

echo ""
echo "4??  SERVICIOS:"
ls -1 services/ 2>/dev/null | grep -E "\.js$" || echo "   (directorio vacío o no existe)"

echo ""
echo "5??  PROCESO NODE:"
ps aux | grep "node.*server" | grep -v grep || echo "   ? No hay proceso corriendo"

echo ""
echo "6??  PUERTO 5000:"
netstat -tlnp 2>/dev/null | grep :5000 || ss -tlnp 2>/dev/null | grep :5000 || echo "   ? Puerto 5000 no está en uso"

echo ""
echo "7??  ÚLTIMOS LOGS:"
tail -10 logs/backend.log 2>/dev/null || echo "   ? No hay logs"

echo ""
echo "8??  MONGODB:"
mongo --eval "db.adminCommand('ping')" 2>/dev/null || mongosh --eval "db.adminCommand('ping')" 2>/dev/null || echo "   ??  No se puede verificar MongoDB"

echo ""
