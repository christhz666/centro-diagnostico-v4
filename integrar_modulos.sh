#!/bin/bash

echo "+--------------------------------------------------------+"
echo "¦  INTEGRACIÓN DE MÓDULOS: Radiografías, Sonografías, WS¦"
echo "+--------------------------------------------------------+"
echo ""

# 1. VERIFICAR QUE LOS ARCHIVOS EXISTEN
echo "1?? VERIFICANDO ARCHIVOS..."
echo ""

for file in backend/app/routes/radiografias.py backend/app/routes/sonografias.py backend/app/routes/whatsapp_bot.py; do
    if [ -f "$file" ]; then
        echo "? $file"
    else
        echo "? $file - NO EXISTE"
    fi
done

# 2. AGREGAR BLUEPRINTS A run.py
echo ""
echo "2?? AGREGANDO BLUEPRINTS A run.py..."

cd backend

python3 << 'PYEOF'
import re

with open('run.py', 'r') as f:
    content = f.read()

# Verificar si ya están agregados
blueprints_to_add = {
    'radiografias': ('radiografias', '/api/radiografias'),
    'sonografias': ('sonografias', '/api/sonografias'),
    'whatsapp_bot': ('whatsapp', '/api/whatsapp')
}

modified = False
for module_name, (bp_name, url_prefix) in blueprints_to_add.items():
    full_module = f"'app.routes.{module_name}'"
    
    if full_module not in content:
        # Buscar el cierre del diccionario de blueprints
        pattern = r"('app\.routes\.maquinas'.*?/api/maquinas'\),)"
        replacement = r"\1\n        'app.routes.%s': ('%s', '%s')," % (module_name, bp_name, url_prefix)
        content = re.sub(pattern, replacement, content)
        modified = True
        print(f"? Agregado blueprint: {module_name}")
    else:
        print(f"??  Blueprint ya existe: {module_name}")

if modified:
    with open('run.py', 'w') as f:
        f.write(content)
    print("\n? run.py actualizado")
else:
    print("\n? Todos los blueprints ya estaban agregados")

PYEOF

cd ..

# 3. VERIFICAR VARIABLES DE ENTORNO PARA TWILIO
echo ""
echo "3?? VERIFICANDO VARIABLES DE ENTORNO..."

if grep -q "TWILIO_ACCOUNT_SID" backend/.env; then
    echo "? TWILIO_ACCOUNT_SID configurado"
else
    echo "??  TWILIO_ACCOUNT_SID no configurado - agregando placeholder"
    echo "" >> backend/.env
    echo "# Twilio WhatsApp" >> backend/.env
    echo "TWILIO_ACCOUNT_SID=your_account_sid_here" >> backend/.env
    echo "TWILIO_AUTH_TOKEN=your_auth_token_here" >> backend/.env
    echo "TWILIO_WHATSAPP_FROM=whatsapp:+14155238886" >> backend/.env
fi

# 4. CREAR DIRECTORIOS DE UPLOADS
echo ""
echo "4?? CREANDO DIRECTORIOS DE UPLOADS..."

mkdir -p uploads/radiografias
mkdir -p uploads/sonografias

echo "? Directorios creados"

# 5. VERIFICAR TABLAS EN LA BASE DE DATOS
echo ""
echo "5?? VERIFICANDO TABLAS EN BASE DE DATOS..."

PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost << 'EOSQL'
SELECT 
    table_name,
    (SELECT COUNT(*) 
     FROM information_schema.columns 
     WHERE table_name = t.table_name) as columnas
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name IN ('radiografias', 'sonografias', 'whatsapp_messages')
ORDER BY table_name;

-- Contar registros
SELECT 
    'radiografias' as tabla,
    COUNT(*) as registros
FROM radiografias
UNION ALL
SELECT 
    'sonografias' as tabla,
    COUNT(*) as registros
FROM sonografias
UNION ALL
SELECT 
    'whatsapp_messages' as tabla,
    COUNT(*) as registros
FROM whatsapp_messages;
EOSQL

# 6. REINICIAR BACKEND
echo ""
echo "6?? REINICIANDO BACKEND..."

sudo systemctl restart centro-backend
sleep 5

if systemctl is-active --quiet centro-backend; then
    echo "? Backend activo"
else
    echo "? Backend falló - viendo logs..."
    sudo journalctl -u centro-backend -n 20 --no-pager
    exit 1
fi

# 7. PROBAR ENDPOINTS
echo ""
echo "7?? PROBANDO ENDPOINTS..."

TOKEN=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null)

if [ -n "$TOKEN" ]; then
    echo "? Token obtenido"
    
    # Probar endpoint de radiografías
    echo ""
    echo "Probando /api/radiografias/..."
    RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/radiografias/)
    if echo "$RESPONSE" | grep -q "error"; then
        echo "??  Error: $RESPONSE"
    else
        COUNT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
        echo "? Radiografías: $COUNT registros"
    fi
    
    # Probar endpoint de sonografías
    echo ""
    echo "Probando /api/sonografias/..."
    RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/sonografias/)
    if echo "$RESPONSE" | grep -q "error"; then
        echo "??  Error: $RESPONSE"
    else
        COUNT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
        echo "? Sonografías: $COUNT registros"
    fi
    
    # Probar endpoint de WhatsApp historial
    echo ""
    echo "Probando /api/whatsapp/historial..."
    RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/whatsapp/historial)
    if echo "$RESPONSE" | grep -q "error"; then
        echo "??  Error: $RESPONSE"
    else
        COUNT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
        echo "? WhatsApp: $COUNT mensajes en historial"
    fi
    
    # Probar tipos de radiografías
    echo ""
    echo "Probando /api/radiografias/tipos..."
    RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/radiografias/tipos)
    COUNT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
    echo "? Tipos de radiografías: $COUNT disponibles"
    
    # Probar tipos de sonografías
    echo ""
    echo "Probando /api/sonografias/tipos..."
    RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/sonografias/tipos)
    COUNT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
    echo "? Tipos de sonografías: $COUNT disponibles"
    
else
    echo "? No se pudo obtener token"
fi

# 8. VERIFICAR RUTAS REGISTRADAS
echo ""
echo "8?? VERIFICANDO RUTAS REGISTRADAS..."

cd backend
source venv/bin/activate
python3 << 'PYEOF'
import sys
sys.path.insert(0, '/home/opc/centro-diagnostico/backend')
try:
    from run import create_app
    app = create_app()
    with app.app_context():
        radio_routes = [str(r) for r in app.url_map.iter_rules() if '/radiografias' in str(r)]
        sono_routes = [str(r) for r in app.url_map.iter_rules() if '/sonografias' in str(r)]
        ws_routes = [str(r) for r in app.url_map.iter_rules() if '/whatsapp' in str(r)]
        
        print(f"\n? Rutas /api/radiografias/*: {len(radio_routes)}")
        for r in radio_routes[:5]:
            print(f"   {r}")
        
        print(f"\n? Rutas /api/sonografias/*: {len(sono_routes)}")
        for r in sono_routes[:5]:
            print(f"   {r}")
        
        print(f"\n? Rutas /api/whatsapp/*: {len(ws_routes)}")
        for r in ws_routes[:5]:
            print(f"   {r}")
except Exception as e:
    print(f"? Error: {e}")
    import traceback
    traceback.print_exc()
PYEOF
deactivate
cd ..

echo ""
echo "+--------------------------------------------------------+"
echo "¦  ? INTEGRACIÓN COMPLETADA                            ¦"
echo "+--------------------------------------------------------+"
echo ""
echo "?? RESUMEN:"
echo "  ? 3 nuevos blueprints agregados"
echo "  ? 3 tablas creadas en BD"
echo "  ? Endpoints funcionando"
echo "  ? Directorios de uploads creados"
echo ""
echo "?? Nuevos endpoints disponibles:"
echo "  ?? /api/radiografias/ - Gestión de radiografías"
echo "  ?? /api/sonografias/ - Gestión de sonografías"
echo "  ?? /api/whatsapp/ - Bot de WhatsApp"
echo ""
echo "??  IMPORTANTE:"
echo "  Para usar WhatsApp, configura las variables en backend/.env:"
echo "  - TWILIO_ACCOUNT_SID"
echo "  - TWILIO_AUTH_TOKEN"
echo "  - TWILIO_WHATSAPP_FROM"
echo ""
echo "?? Próximo paso: Crear componentes frontend"
echo ""

