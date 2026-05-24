# Documentación Técnica - Práctica Final EAFIT

## 1. Descripción del Sistema

### Objetivo
Implementar una aplicación web segura con balanceo de carga que permita registrar estudiantes interesados en programas académicos de la Universidad EAFIT.

### Componentes Principales

#### 1.1 Servidor Web Flask (Python)
- **Propósito**: Aplicación principal para registro de usuarios
- **Versiones**: Inglés (port 5000) y Español (port 5000)
- **Framework**: Flask 3.0.0
- **Base de datos**: MySQL 8.0
- **Servidor WSGI**: Gunicorn (4 workers)

#### 1.2 Balanceador de Carga (NGINX)
- **Propósito**: Distribuir tráfico entre servidores y actuar como proxy inverso
- **Política**: Round Robin
- **Puertos**: 80 (HTTP → HTTPS), 443 (HTTPS)
- **SSL/TLS**: TLSv1.2 y TLSv1.3

#### 1.3 Base de Datos (MySQL)
- **Propósito**: Almacenamiento de registros de usuarios
- **Tabla principal**: registros
- **Índices**: comuna, carrera, fecha

#### 1.4 Aplicación de Estadísticas (Python)
- **Propósito**: Generar reportes y gráficas
- **Puerto**: 5001
- **Funcionalidad**: 
  - Gráficas de registros
  - Análisis cruzado
  - Envío de correos

---

## 2. Estructura de Base de Datos

### Tabla: registros

```sql
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

### Datos Principales

**Comunas**: 10 zonas numeradas (Comuna 1 - Comuna 10)

**Carreras**:
- Medicina
- Ingeniería
- Abogacía
- Licenciatura

---

## 3. Endpoints de la Aplicación

### Aplicación Principal

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/` | Redirige a versión en español |
| GET | `/es` | Formulario en español |
| GET | `/en` | Formulario en inglés |
| POST | `/register` | Envía nuevo registro |
| GET | `/health` | Health check |

### Aplicación de Estadísticas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/stats` | Dashboard de estadísticas |
| GET | `/api/statistics` | JSON con estadísticas |
| POST | `/api/send-report` | Envía reporte por correo |

---

## 4. Configuración de NGINX

### Upstreams

```nginx
upstream app_es {
    server web-es:5000;
}

upstream app_en {
    server web-en:5000;
}

upstream estadisticas {
    server stats:5001;
}
```

### Rutas

- `/es` → Servidor en español
- `/en` → Servidor en inglés
- `/stats` → Panel de estadísticas
- `/api/*` → APIs de estadísticas

### Seguridad

- HTTP redirige a HTTPS (301)
- Headers de seguridad:
  - Strict-Transport-Security
  - X-Content-Type-Options
  - X-Frame-Options
  - X-XSS-Protection

---

## 5. Instalación y Despliegue

### 5.1 Requisitos

```bash
# Linux/Mac
sudo apt-get install docker.io docker-compose openssl git

# Windows
# Descargar Docker Desktop desde docker.com
```

### 5.2 Pasos de Instalación

```bash
# 1. Clonar repositorio
git clone <url-repositorio>
cd PracticaFinal

# 2. Configurar variables de entorno
cp .env.example .env
nano .env  # Editar con tus valores

# 3. Generar certificados SSL
bash generate_certs.sh  # Linux/Mac
powershell -ExecutionPolicy Bypass -File generate_certs.ps1  # Windows

# 4. Iniciar servicios
docker-compose up -d

# 5. Verificar estado
docker-compose ps
```

### 5.3 Verificación de Servicios

```bash
# Logs en tiempo real
docker-compose logs -f

# Verificar salud de servicios
docker-compose ps

# Conectar a BD
docker-compose exec db mysql -u root -p usuarios
```

---

## 6. Configuración de Dominio

### 6.1 Registrar Dominio Gratuito

1. Ir a https://www.freenom.com/
2. Buscar dominio (.tk, .ml, .ga, .cf)
3. Registrar por 3 meses
4. Anotar los nameservers

### 6.2 Configurar DNS

Crear registros A en el proveedor DNS:

```
A record: @ (raíz) → IP_PUBLICA_AWS
A record: www → IP_PUBLICA_AWS
```

### 6.3 Certificado SSL Real (Let's Encrypt)

```bash
# Instalar Certbot
sudo apt-get install certbot

# Obtener certificado
sudo certbot certonly --standalone -d tudominio.tk -d www.tudominio.tk

# Copiar certificados a NGINX
sudo cp /etc/letsencrypt/live/tudominio.tk/fullchain.pem certs/server.crt
sudo cp /etc/letsencrypt/live/tudominio.tk/privkey.pem certs/server.key

# Reiniciar NGINX
docker-compose restart nginx
```

---

## 7. Despliegue en AWS

### 7.1 Crear Instancia EC2

1. Ir a AWS Console
2. Crear instancia Ubuntu 20.04 LTS o superior
3. Asignar grupo de seguridad con puertos:
   - 80 (HTTP)
   - 443 (HTTPS)
   - 3306 (MySQL - restringido)

### 7.2 Configurar Instancia

```bash
# Actualizar sistema
sudo apt-get update && sudo apt-get upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clonar proyecto
git clone <url-repositorio>
cd PracticaFinal
```

### 7.3 Iniciar Servicios en AWS

```bash
# Copiar archivo .env con contraseñas seguras
cp .env.example .env
nano .env

# Generar certificados
bash generate_certs.sh

# Iniciar servicios
docker-compose up -d

# Configurar auto-reinicio
sudo systemctl enable docker
```

---

## 8. Configuración SMTP (Correos)

### Usando Gmail

1. Activar contraseñas de aplicación:
   - Ir a myaccount.google.com
   - Seguridad → Contraseñas de aplicación
   - Seleccionar "Correo" y "Windows"

2. Actualizar `.env`:
   ```env
   SMTP_SERVER=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=tu_email@gmail.com
   SMTP_PASSWORD=contraseña_app
   ```

3. Reiniciar servicios:
   ```bash
   docker-compose restart stats
   ```

---

## 9. Seguridad

### 9.1 Contraseñas

| Componente | Usuario | Contraseña (Cambiar) |
|-----------|---------|---------------------|
| MySQL | root | eafit_2025_secure |
| Estadísticas | admin | admin123 |

### 9.2 SSL/TLS

- Certificados autofirmados para desarrollo
- Let's Encrypt para producción
- Redirección HTTP → HTTPS
- Headers de seguridad en NGINX

### 9.3 Firewall

```bash
# UFW (Linux)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
```

---

## 10. Monitoreo y Logs

### 10.1 Ver Logs

```bash
# Todos los servicios
docker-compose logs -f

# Servicio específico
docker-compose logs -f nginx
docker-compose logs -f web-es
docker-compose logs -f db
```

### 10.2 Health Checks

Cada contenedor tiene health checks:

```bash
# Ver estado
docker-compose ps

# Verificar desde navegador
curl -k https://localhost/health
```

---

## 11. Backup y Recuperación

### 11.1 Backup de Base de Datos

```bash
# Hacer backup
docker-compose exec db mysqldump -u root -p usuarios > backup_$(date +%Y%m%d).sql

# Restaurar
docker-compose exec -T db mysql -u root -p usuarios < backup_20250527.sql
```

### 11.2 Backup de Volúmenes

```bash
# Ver volúmenes
docker volume ls

# Backup de datos
docker run --rm -v practicafinal_db_data:/data -v $(pwd):/backup alpine tar czf /backup/db_backup.tar.gz /data
```

---

## 12. Solución de Problemas

### 12.1 Servicios no inician

```bash
# Ver logs de error
docker-compose logs

# Reconstruir imágenes
docker-compose up -d --build

# Reiniciar servicios
docker-compose restart
```

### 12.2 Error de conexión a BD

```bash
# Verificar estado de MySQL
docker-compose logs db

# Esperar a que la BD inicie
docker-compose exec db mysqladmin ping -u root -p
```

### 12.3 Error de certificado SSL

```bash
# Regenerar certificados
bash generate_certs.sh

# Reiniciar NGINX
docker-compose restart nginx
```

---

## 13. Testing

### 13.1 Pruebas Funcionales

```bash
# Registrar usuario
curl -X POST https://localhost/register \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Juan","comuna":"Comuna 1","carrera":"Medicina"}' \
  -k

# Obtener estadísticas
curl -k https://localhost/api/statistics

# Enviar reporte
curl -X POST "https://localhost/api/send-report?password=admin123" -k
```

### 13.2 Carga Simultánea

```bash
# Usar Apache Bench
ab -n 100 -c 10 https://localhost/ -k

# O usar wrk
wrk -t4 -c10 -d30s https://localhost/
```

---

## 14. Mantenimiento

### 14.1 Actualizar Dependencias

```bash
# Actualizar imágenes base
docker-compose pull

# Reconstruir con nuevas versiones
docker-compose up -d --build
```

### 14.2 Limpiar Recursos

```bash
# Eliminar contenedores detenidos
docker-compose down

# Eliminar imágenes no usadas
docker image prune -a

# Eliminar volúmenes (cuidado: borra datos)
docker-compose down -v
```

---

## 15. Documentación de Código

### 15.1 app-web/app.py

- Rutas principales: `/`, `/es`, `/en`, `/register`
- Conexión MySQL con Flask-MySQLdb
- Validación de datos
- Respuestas JSON

### 15.2 app-estadisticas/app.py

- Generación de gráficas con Matplotlib
- Análisis de datos
- Envío de correos con SMTP
- API RESTful

### 15.3 nginx/nginx.conf

- Configuración de upstreams
- Balanceo round robin
- Redireccionamiento HTTP → HTTPS
- Headers de seguridad

---

## 16. Referencias

- Flask: https://flask.palletsprojects.com/
- NGINX: https://nginx.org/en/docs/
- MySQL: https://dev.mysql.com/doc/
- Docker: https://docs.docker.com/
- Let's Encrypt: https://letsencrypt.org/

---

## 17. Checklist Final

- [ ] Código en GitHub
- [ ] README.md completo
- [ ] docker-compose.yml funcional
- [ ] Certificados SSL generados
- [ ] Base de datos inicializada
- [ ] Pruebas en localhost
- [ ] Dominio registrado
- [ ] DNS configurado
- [ ] Instancia AWS creada
- [ ] Servicios en AWS funcionando
- [ ] Correos funcionando
- [ ] Documentación PDF lista
- [ ] Sustentación preparada

---

**Fecha**: Mayo 2025  
**Versión**: 1.0  
**Autores**: Equipo de Práctica Final
