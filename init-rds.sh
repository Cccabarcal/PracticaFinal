#!/bin/bash
# Script para inicializar base de datos RDS
# Ejecutar desde: bash init-rds.sh

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║   Inicialización de Base de Datos RDS                 ║"
echo "║   EAFIT - PracticaFinal                               ║"
echo "╚════════════════════════════════════════════════════════╝"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# Variables
RDS_HOST=${1:-"eafit-mysql-db.c9akciq32.us-east-1.rds.amazonaws.com"}
DB_USER=${2:-"admin"}
DB_PASSWORD=${3:-""}
DB_NAME=${4:-"usuarios"}

if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}Error: Se requiere contraseña de base de datos${NC}"
    echo "Uso: bash init-rds.sh [host] [user] [password] [dbname]"
    exit 1
fi

echo -e "${YELLOW}Parámetros:${NC}"
echo "  Host: $RDS_HOST"
echo "  Usuario: $DB_USER"
echo "  Base de datos: $DB_NAME"

# Verificar conexión
echo -e "${BLUE}▶ Verificando conexión a RDS...${NC}"
if ! mysql -h "$RDS_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
    echo -e "${RED}✗ No se puede conectar a RDS${NC}"
    echo "  Verifique:"
    echo "  • Host: $RDS_HOST"
    echo "  • Usuario: $DB_USER"
    echo "  • Contraseña"
    echo "  • Security Group permite conexión desde su IP"
    exit 1
fi
echo -e "${GREEN}✓ Conexión exitosa${NC}"

# Crear database
echo -e "${BLUE}▶ Creando base de datos: $DB_NAME${NC}"
mysql -h "$RDS_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
echo -e "${GREEN}✓ Base de datos creada${NC}"

# Crear tabla
echo -e "${BLUE}▶ Creando tabla 'registros'${NC}"
mysql -h "$RDS_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" << 'EOF'
CREATE TABLE IF NOT EXISTS registros (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(255) NOT NULL COLLATE utf8mb4_unicode_ci,
  comuna VARCHAR(50) NOT NULL COLLATE utf8mb4_unicode_ci,
  carrera VARCHAR(100) NOT NULL COLLATE utf8mb4_unicode_ci,
  fecha DATE DEFAULT CURDATE(),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHARSET=utf8mb4,
  COLLATE=utf8mb4_unicode_ci,
  INDEX idx_comuna (comuna),
  INDEX idx_carrera (carrera),
  INDEX idx_fecha (fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF
echo -e "${GREEN}✓ Tabla creada${NC}"

# Insertar datos de prueba
echo -e "${BLUE}▶ Insertando datos de prueba${NC}"
mysql -h "$RDS_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" << 'EOF'
INSERT INTO registros (nombre, comuna, carrera) VALUES
('María José González', 'Comuna 1', 'Medicina'),
('Andrés Felipe López', 'Comuna 2', 'Ingeniería'),
('Catalina Rodríguez', 'Comuna 3', 'Abogacía'),
('Diego Sánchez', 'Comuna 4', 'Licenciatura'),
('Francisco Córdoba', 'Comuna 5', 'Medicina');
EOF
echo -e "${GREEN}✓ Datos de prueba insertados${NC}"

# Verificar datos
echo -e "${BLUE}▶ Verificando datos${NC}"
TOTAL=$(mysql -h "$RDS_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -se "SELECT COUNT(*) FROM registros;")
echo -e "${GREEN}✓ Total de registros: $TOTAL${NC}"

# Mostrar datos
echo -e "${BLUE}▶ Mostrando registros${NC}"
mysql -h "$RDS_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" << 'EOF'
SELECT id, nombre, comuna, carrera, fecha FROM registros ORDER BY id;
EOF

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Inicialización Completada                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
