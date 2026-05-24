# Comandos Útiles - Referencia Rápida

## 🐳 Docker & Docker Compose

### Iniciar y Detener

```bash
# Iniciar servicios
docker-compose up -d

# Iniciar con build
docker-compose up -d --build

# Ver estado de servicios
docker-compose ps

# Detener servicios
docker-compose down

# Detener y eliminar volúmenes (cuidado!)
docker-compose down -v

# Reiniciar servicios
docker-compose restart

# Reiniciar servicio específico
docker-compose restart nginx
docker-compose restart web-es
docker-compose restart db
docker-compose restart stats
```

### Logs y Monitoreo

```bash
# Ver logs de todos los servicios
docker-compose logs

# Ver logs en tiempo real (sigue logs)
docker-compose logs -f

# Ver logs de servicio específico
docker-compose logs -f nginx
docker-compose logs -f web-es
docker-compose logs -f web-en
docker-compose logs -f db
docker-compose logs -f stats

# Últimas 50 líneas
docker-compose logs --tail=50

# Logs desde las últimas 2 horas
docker-compose logs --since 2h

# Ver uso de recursos
docker stats

# Ver información de contenedores
docker ps
docker ps -a
docker container inspect <container_id>
```

### Ejecución de Comandos

```bash
# Ejecutar comando en contenedor
docker-compose exec <servicio> <comando>

# Abrir shell interactivo
docker-compose exec web-es bash
docker-compose exec nginx sh
docker-compose exec db bash

# Sin interactividad (-T)
docker-compose exec -T db mysql -u root -p usuarios -e "SELECT * FROM registros;"
```

---

## 🗄️ Base de Datos

### Conexión MySQL

```bash
# Conectar a BD
docker-compose exec db mysql -u root -p usuarios

# Sin solicitar contraseña (inseguro, solo desarrollo)
docker-compose exec -T db mysql -u root -peafit_2025_secure usuarios
```

### Comandos SQL

```sql
-- Ver tabla de registros
SELECT * FROM registros;

-- Contar total de registros
SELECT COUNT(*) FROM registros;

-- Registros por comuna
SELECT comuna, COUNT(*) FROM registros GROUP BY comuna;

-- Registros por carrera
SELECT carrera, COUNT(*) FROM registros GROUP BY carrera;

-- Análisis cruzado
SELECT comuna, carrera, COUNT(*) FROM registros GROUP BY comuna, carrera;

-- Últimos registros
SELECT * FROM registros ORDER BY fecha DESC LIMIT 10;

-- Borrar todos los registros (cuidado!)
DELETE FROM registros;

-- Borrar tabla
DROP TABLE registros;

-- Crear tabla nuevamente
CREATE TABLE registros (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    comuna VARCHAR(100) NOT NULL,
    carrera VARCHAR(100) NOT NULL,
    fecha DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Backup

```bash
# Hacer backup
docker-compose exec db mysqldump -u root -p usuarios > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurar backup
docker-compose exec -T db mysql -u root -p usuarios < backup_20250527_143025.sql

# Backup completo con estructura
docker-compose exec db mysqldump -u root -p --all-databases > full_backup.sql
```

---

## 🌐 Pruebas de Conectividad

### Health Checks

```bash
# Verificar aplicación web
curl -k https://localhost/health

# Verificar estadísticas
curl -k https://localhost/stats/health

# Verificar todos con un script
for service in "web-es" "web-en" "stats"; do
  echo "Testing $service..."
  curl -k https://localhost/health
done
```

### Solicitudes HTTP

```bash
# GET simple
curl -k https://localhost/es

# GET con headers
curl -k -H "Content-Type: application/json" https://localhost/api/statistics

# POST con JSON
curl -k -X POST https://localhost/register \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Juan García",
    "comuna": "Comuna 1",
    "carrera": "Medicina"
  }'

# POST para enviar reporte
curl -k -X POST "https://localhost/api/send-report?password=admin123"

# Verbose (ver headers)
curl -k -v https://localhost/es

# Guardar respuesta en archivo
curl -k https://localhost/api/statistics > response.json
```

---

## 🔧 Configuración y Variables

### Cambiar Contraseñas

```bash
# Editar archivo .env
nano .env

# Variables importantes:
# DB_PASSWORD=nueva_contraseña
# ADMIN_PASSWORD=nueva_contraseña_admin
# SMTP_USER=email@gmail.com
# SMTP_PASSWORD=contraseña_app

# Reiniciar servicios para aplicar cambios
docker-compose up -d
```

### Ver Variables de Entorno en un Contenedor

```bash
docker-compose exec web-es env
docker-compose exec db env
```

---

## 🔒 Certificados SSL

### Generar Certificados

```bash
# Certificado autofirmado (desarrollo)
bash generate_certs.sh

# Manualmente con openssl
openssl req -x509 -newkey rsa:4096 -nodes \
  -out certs/server.crt \
  -keyout certs/server.key \
  -days 365 \
  -subj "/C=CO/ST=Antioquia/L=Medellin/O=EAFIT/CN=localhost"
```

### Verificar Certificados

```bash
# Ver información del certificado
openssl x509 -in certs/server.crt -text -noout

# Ver fecha de expiración
openssl x509 -in certs/server.crt -noout -dates

# Verificar que key y cert coinciden
diff <(openssl x509 -noout -modulus -in certs/server.crt | openssl md5) \
     <(openssl rsa -noout -modulus -in certs/server.key | openssl md5)
```

---

## 📊 Estadísticas y Reportes

### Ver Estadísticas en Navegador

```bash
# Ir a https://localhost/stats
# Contraseña: admin123
```

### API de Estadísticas

```bash
# JSON con estadísticas
curl -k https://localhost/api/statistics | jq

# Guardar en archivo
curl -k https://localhost/api/statistics > stats.json
```

### Descarga de CSV

```bash
# Desde el dashboard de estadísticas, hay botón de descarga
# O crear manualmente con consulta SQL
docker-compose exec -T db mysql -u root -peafit_2025_secure usuarios \
  -e "SELECT * FROM registros;" > registros.csv
```

---

## 🧹 Limpieza y Mantenimiento

### Eliminar Contenedores No Usados

```bash
# Eliminar contenedores detenidos
docker container prune

# Eliminar imágenes no usadas
docker image prune

# Eliminar volúmenes no usados
docker volume prune

# Todo lo anterior en uno
docker system prune -a
```

### Actualizar Imágenes Base

```bash
# Descargar últimas versiones
docker-compose pull

# Reconstruir con nuevas imágenes
docker-compose up -d --build
```

### Logs de Almacenamiento

```bash
# Ver tamaño de los logs
docker inspect -f '{{.LogPath}}' <container_id>

# Limpiar logs (requiere reinicio)
docker-compose down
docker system prune --volumes
```

---

## 🐛 Debugging

### Ver Configuración Completa

```bash
# docker-compose con variables interpoladas
docker-compose config

# Ver puerto de un contenedor
docker port <container_id>

# Ver variables de entorno
docker inspect -e <container_id>
```

### Acceder a Directorios de Contenedores

```bash
# Copiar archivo desde contenedor
docker cp <container_id>:/app/file.txt ./local_file.txt

# Copiar archivo a contenedor
docker cp ./local_file.txt <container_id>:/app/file.txt
```

### Ver Procesos en Contenedor

```bash
# Ver procesos
docker-compose exec web-es ps aux

# Ver conexiones de red
docker-compose exec web-es netstat -tlnp
```

---

## 🚀 Despliegue en AWS

### Conectar a Instancia EC2

```bash
# Linux/Mac
ssh -i ~/Downloads/eafit-key.pem ubuntu@IP_PUBLICA

# Windows (usar PuTTY o WSL)
ssh -i eafit-key.pem ubuntu@IP_PUBLICA

# O desde el navegador (AWS EC2 Instance Connect)
```

### Comandos en el Servidor

```bash
# Actualizar sistema
sudo apt-get update && sudo apt-get upgrade -y

# Ver espacio disponible
df -h

# Ver uso de memoria
free -h

# Ver procesos
top

# Monitorear logs en tiempo real
tail -f /var/log/syslog
```

---

## 📈 Análisis de Rendimiento

### Prueba de Carga

```bash
# Apache Bench (ab) - instalable con apache2-utils
ab -n 1000 -c 10 https://localhost/ -k

# wrk - herramienta de benchmarking
wrk -t4 -c100 -d30s https://localhost/

# Explicación:
# -t4: 4 threads
# -c100: 100 conexiones concurrentes
# -d30s: duración de 30 segundos
```

### Monitoreo de Recursos

```bash
# Ver uso de CPU y memoria
docker stats

# Con filtro por contenedor
docker stats eafit_web_es eafit_nginx eafit_db
```

---

## 📝 Tareas Comunes

### Agregar usuario de prueba a BD

```bash
docker-compose exec -T db mysql -u root -peafit_2025_secure usuarios << EOF
INSERT INTO registros (nombre, comuna, carrera, fecha) VALUES
('Ana García Pérez', 'Comuna 1', 'Medicina', NOW()),
('Carlos López Rodríguez', 'Comuna 2', 'Ingeniería', NOW()),
('María Santos Martínez', 'Comuna 3', 'Abogacía', NOW());
EOF
```

### Resetear Base de Datos

```bash
# Eliminar volumen de BD
docker-compose down -v

# Reiniciar servicios (esto reinicializa BD)
docker-compose up -d
```

### Cambiar Idioma del Servidor Web

En `docker-compose.yml`, cambiar:

```yaml
web-es:
  environment:
    LANGUAGE: es

web-en:
  environment:
    LANGUAGE: en
```

---

## ⚡ Alias Útiles

```bash
# Agregar a ~/.bashrc o ~/.zshrc

alias dc='docker-compose'
alias dcd='docker-compose down'
alias dcu='docker-compose up -d'
alias dcl='docker-compose logs -f'
alias dcp='docker-compose ps'
alias dcr='docker-compose restart'

# Luego usar:
# dc up -d
# dcp
# dcl nginx
```

---

## 🔗 Recursos Rápidos

| Recurso | URL |
|---------|-----|
| Aplicación (Español) | https://localhost/es |
| Aplicación (Inglés) | https://localhost/en |
| Estadísticas | https://localhost/stats |
| API | https://localhost/api/statistics |
| MySQL | localhost:3306 |
| Documentación | README.md |

---

¡Con esta guía deberías cubrir la mayoría de casos de uso! 📚
