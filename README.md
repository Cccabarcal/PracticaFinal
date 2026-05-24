# Práctica Final - Sistema de Registros EAFIT

## 📋 Descripción General

Sistema web completo para registrar estudiantes interesados en programas académicos de la Universidad EAFIT. Incluye:

- ✅ Aplicación web bilingüe (Español e Inglés)
- ✅ Balanceador de carga con NGINX (Round Robin)
- ✅ Base de datos MySQL
- ✅ Panel de estadísticas con gráficas
- ✅ SSL/TLS seguro
- ✅ Docker para toda la infraestructura

---

## 🏗️ Arquitectura del Proyecto

```
PracticaFinal/
├── app-web/              # Aplicación principal Flask
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── templates/
│       ├── index_es.html
│       └── index_en.html
├── app-estadisticas/     # Aplicación de reportes
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── templates/
│       └── dashboard.html
├── nginx/                # Configuración del balanceador
│   └── nginx.conf
├── database/             # Scripts de inicialización
│   └── init.sql
├── certs/                # Certificados SSL
│   ├── server.crt
│   └── server.key
├── docker-compose.yml
├── .env.example
└── README.md
```

---

## 🚀 Instalación y Despliegue

### Requisitos Previos

- Docker (versión 20.10+)
- Docker Compose (versión 1.29+)
- Git

### Pasos de Instalación

#### 1. Clonar el repositorio

```bash
git clone <tu-repositorio>
cd PracticaFinal
```

#### 2. Configurar variables de entorno

```bash
cp .env.example .env
```

Edita el archivo `.env` con tus valores:

```env
DB_PASSWORD=tu_contraseña_segura
ADMIN_PASSWORD=tu_contraseña_admin
SMTP_USER=tu_email@gmail.com
SMTP_PASSWORD=tu_contraseña_app
```

#### 3. Generar certificados SSL

```bash
# En Linux/Mac
./generate_certs.sh

# En Windows PowerShell
.\generate_certs.ps1

# O manualmente con OpenSSL:
openssl req -x509 -newkey rsa:4096 -nodes -out certs/server.crt -keyout certs/server.key -days 365
```

#### 4. Iniciar los servicios

```bash
docker-compose up -d
```

#### 5. Verificar el estado

```bash
docker-compose ps
docker-compose logs -f
```

---

## 📍 Acceder a los Servicios

- **Aplicación Web (Español)**: https://localhost/es
- **Aplicación Web (Inglés)**: https://localhost/en
- **Panel de Estadísticas**: https://localhost/stats
- **API de Estadísticas**: https://localhost/api/statistics

> **Nota**: Los navegadores mostrarán una advertencia de certificado no confiable. Esto es normal en desarrollo. Haz clic en "Avanzado" y procede.

---

## 🔐 Seguridad

### Contraseñas Predeterminadas

| Servicio | Usuario | Contraseña |
|----------|---------|-----------|
| MySQL | root | `eafit_2025_secure` |
| Estadísticas | admin | `admin123` |

**⚠️ IMPORTANTE**: Cambia estas contraseñas en producción.

---

## 📊 Base de Datos

### Tabla de Registros

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

### Conectarse a la Base de Datos

```bash
docker-compose exec db mysql -u root -p usuarios
```

---

## 🌍 Configuración del Dominio

### Registrar un dominio gratuito

1. Ve a https://www.freenom.com/
2. Busca un dominio disponible (.tk, .ml, .ga, .cf)
3. Registra el dominio por 3 meses (gratis)

### Configurar los registros DNS

En tu proveedor DNS, crea:

| Tipo | Nombre | Valor |
|------|--------|-------|
| A | @ | Tu IP pública de AWS |
| A | www | Tu IP pública de AWS |

Ejemplo con la IP `54.123.45.67`:

```
A   @     54.123.45.67
A   www   54.123.45.67
```

### Certificado SSL para dominio real

Usa Let's Encrypt (gratuito):

```bash
# Instalar Certbot
sudo apt-get install certbot python3-certbot-nginx

# Obtener certificado
sudo certbot certonly --standalone -d tudominio.tk

# Los certificados estarán en:
# /etc/letsencrypt/live/tudominio.tk/
```

---

## 📧 Configurar Envío de Correos

### Usando Gmail

1. Habilita "Contraseñas de aplicación" en tu cuenta de Google
2. En el archivo `.env`:
   ```env
   SMTP_USER=tu_email@gmail.com
   SMTP_PASSWORD=tu_contraseña_app
   ```

3. Para enviar el reporte:
   - Ve a https://localhost/stats
   - Haz clic en "Enviar Reporte por Correo"
   - Ingresa la contraseña: `admin123`

---

## 🐛 Solución de Problemas

### Los contenedores no inician

```bash
# Ver logs
docker-compose logs

# Reiniciar servicios
docker-compose restart

# Reconstruir imágenes
docker-compose up -d --build
```

### Error de conexión a la base de datos

```bash
# Verificar que la BD esté lista
docker-compose logs db

# Esperar unos segundos y reintentar
```

### Certificado SSL no confiable

Este es el comportamiento esperado en desarrollo. Para producción:
1. Usa Let's Encrypt en AWS
2. Configura un dominio real
3. Actualiza el certificado en NGINX

---

## 📱 Formulario de Registro

El formulario permite:

- ✅ Ingresar nombre completo
- ✅ Seleccionar zona de comuna (1-10)
- ✅ Seleccionar carrera:
  - Medicina
  - Ingeniería
  - Abogacía
  - Licenciatura
- ✅ Fecha de registro automática
- ✅ Validación cliente y servidor

---

## 📈 Panel de Estadísticas

Ofrece:

- 📊 Gráficas de registros por comuna
- 📊 Distribución por carrera
- 📋 Tablas detalladas
- 📧 Envío de reportes por correo
- 📥 Descarga en CSV

**Contraseña de acceso**: `admin123`

---

## 🔄 Round Robin en NGINX

El balanceador distribuye las solicitudes entre los dos servidores web:

```nginx
upstream app_es {
    server web-es:5000;
}

upstream app_en {
    server web-en:5000;
}

# Las solicitudes se distribuyen automáticamente
```

---

## 🐳 Comandos Docker Útiles

```bash
# Ver estado de contenedores
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f nginx

# Ejecutar comando en un contenedor
docker-compose exec db mysql -u root -p usuarios

# Detener servicios
docker-compose down

# Eliminar volúmenes (cuidado: borra datos)
docker-compose down -v

# Reconstruir imágenes
docker-compose build --no-cache
```

---

## 📄 Archivos Importantes

| Archivo | Propósito |
|---------|-----------|
| `docker-compose.yml` | Orquestación de contenedores |
| `app-web/app.py` | Lógica principal de la aplicación |
| `nginx/nginx.conf` | Configuración del balanceador |
| `database/init.sql` | Inicialización de la BD |
| `.env` | Variables de entorno (no subir a Git) |

---

## 🎯 Próximos Pasos

1. **Desplegar en AWS**:
   - Usa EC2 para la instancia
   - Configura Security Groups
   - Asigna IP elástica

2. **Registrar dominio**:
   - Freenom o GoDaddy
   - Apunta al IP público de AWS

3. **SSL con Let's Encrypt**:
   - Usa Certbot en la instancia
   - Actualiza NGINX con los certificados

4. **Documentación**:
   - Sube el PDF a GitHub
   - Incluye capturas de pantalla
   - Documenta el proceso de despliegue

---

## 📞 Contacto

Para preguntas o problemas, contacta al equipo de desarrollo.

---

## ✅ Checklist de Entrega

- [ ] Aplicación web funcionando
- [ ] Base de datos con datos
- [ ] Balanceador de carga activo
- [ ] Panel de estadísticas
- [ ] Certificado SSL
- [ ] Dominio registrado
- [ ] Documentación completa
- [ ] GitHub con código
- [ ] PDF de documentación
- [ ] Sustentación preparada

---

**Última actualización**: Mayo 2025
