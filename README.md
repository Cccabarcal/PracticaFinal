# Práctica Final - Sistema de Registros EAFIT

## 📋 Descripción General

Sistema web completo para registrar estudiantes interesados en programas académicos de la Universidad EAFIT, con:

- ✅ Aplicación web bilingüe (Español e Inglés)
- ✅ Balanceador de carga con NGINX (Round Robin)
- ✅ Base de datos MySQL 8.0 con UTF-8
- ✅ Dashboard de estadísticas con gráficas
- ✅ Envío de reportes por email
- ✅ SSL/TLS seguro
- ✅ Despliegue en Docker y AWS

---

## 📚 Documentación Esencial

### 1. **CONFIGURACION_Y_DESPLIEGUE.md** ⭐ COMIENZA AQUÍ
   - Requisitos del sistema
   - Arquitectura completa
   - Guía paso a paso local y AWS
   - Configuración de DuckDNS
   - Testing y troubleshooting

### 2. **AWS_README.md**
   - Resumen de despliegue en AWS
   - Quick start (5 minutos)
   - Costos y presupuesto
   - Scripts y herramientas

---

## 🏗️ Estructura del Proyecto

```
├── app-web/                   # Formularios de registro
│   ├── templates/
│   │   ├── index_es.html     # Formulario en español
│   │   └── index_en.html     # Formulario en inglés
│   └── app.py
├── app-estadisticas/          # Dashboard de estadísticas
│   ├── templates/
│   │   └── dashboard.html
│   └── app.py
├── nginx/                     # Proxy inverso y balanceador
│   └── nginx.conf
├── database/                  # Inicialización DB
│   └── init.sql
├── CONFIGURACION_Y_DESPLIEGUE.md  ⭐ LEER PRIMERO
├── AWS_README.md              # AWS + DuckDNS
├── aws-deploy.ps1             # Script de automatización
├── ecs-task-definition.json   # Configuración ECS
├── docker-compose.yml         # Orquestación local
└── .env.example               # Variables de entorno
```

---

## 🚀 Quick Start Local (3 minutos)

```bash
# 1. Clonar/descargar proyecto
cd PracticaFinal

# 2. Configurar variables
cp .env.example .env

# 3. Iniciar servicios
docker-compose up -d

# 4. Acceder a la aplicación
# Español: http://localhost/es
# Inglés: http://localhost/en
# Estadísticas: http://localhost/stats?password=admin123
```

---

## ☁️ Despliegue en AWS (30 minutos)

```powershell
# 1. Instalar AWS CLI
choco install awscli

# 2. Configurar credenciales
aws configure

# 3. Ejecutar despliegue
.\aws-deploy.ps1 -Action setup-all

# 4. Configurar DuckDNS
# Ir a https://www.duckdns.org
# Crear dominio y apuntar al ALB

# 5. Acceder
# http://proyectoiota.duckdns.org/stats
# https://proyectoiota.duckdns.org/stats (con SSL)
```

**Ver documentación completa en CONFIGURACION_Y_DESPLIEGUE.md**

---

## 💻 Componentes Principales

### **Servidor Web (Flask)**
- Puertos: 5000 (interno)
- Versiones: Español e Inglés
- Framework: Flask 3.0.0
- Servidor: Gunicorn 4 workers

### **Estadísticas (Flask)**
- Puerto: 5001 (interno)
- Gráficas: Matplotlib 3.8.2
- Email: SMTP Gmail
- Reportes: HTML formateado

### **Proxy Inverso (NGINX)**
- Puertos: 80 (HTTP), 443 (HTTPS)
- Balanceo: Round Robin
- Certificado: SSL/TLS (ACM en AWS)
- Headers de seguridad

### **Base de Datos (MySQL)**
- Versión: 8.0
- Charset: utf8mb4
- Almacenamiento: Volumen persistente
- Tabla: registros (id, nombre, comuna, carrera, fecha)

---

## ✨ Características

### 📝 Formulario de Registro
- Nombre completo (validado)
- Selección de comuna (10 opciones)
- Selección de carrera (4 opciones)
- Soporte multiidioma (ES/EN)
- Mensajes de confirmación

### 📊 Dashboard de Estadísticas
- Resumen general (total registros)
- Gráficas por comuna
- Gráficas por carrera
- Análisis cruzado (comuna × carrera)
- Tabla de datos completa

### 📧 Reportes por Email
- Autenticación con contraseña
- Email destinatario configurable
- Contenido HTML formateado
- Gráficas incluidas en el correo

### 🎨 Diseño
- Tema moderno negro/morado
- Responsive (móvil, tablet, desktop)
- Gradientes y efectos visuales
- Iconos y animaciones

---

## 🔧 Configuración

### Variables de Entorno (.env)

```env
# Base de datos
DB_HOST=db
DB_USER=root
DB_PASSWORD=eafit_2025_secure
DB_NAME=usuarios

# Administración
ADMIN_PASSWORD=admin123

# Email (SMTP Gmail)
SMTP_USER=tu-email@gmail.com
SMTP_PASSWORD=tu-app-password
```

---

## 🧪 Testing

### Local
```bash
# Probar formulario de registro
curl -X POST http://localhost/register \
  -d "nombre=Test&comuna=Comuna 1&carrera=Ingeniería"

# Ver estadísticas
curl http://localhost/stats?password=admin123

# Enviar email
curl -X POST "http://localhost/api/send-report?password=admin123&email=test@example.com"
```

### AWS
```powershell
# Verificar recursos
aws ec2 describe-instances --region us-east-1
aws rds describe-db-instances --region us-east-1
aws ecs list-clusters --region us-east-1

# Ver logs
aws logs tail /ecs/eafit-web-es --follow
```

---

## 📦 Dependencias

### Python
- Flask 3.0.0
- Matplotlib 3.8.2
- Gunicorn 21.2.0
- PyMySQL 1.1.0
- python-dotenv 1.0.0

### Docker
- nginx:1.25-alpine
- python:3.11-slim
- mysql:8.0

### AWS
- ECR (Container Registry)
- ECS Fargate (Orquestación)
- RDS MySQL (Base de datos)
- ALB (Load Balancer)
- ACM (Certificados SSL)

---

## 🔐 Seguridad

✓ Certificados SSL/TLS (ACM + DuckDNS)  
✓ Contraseña para acceso a estadísticas  
✓ UTF-8 completo (sin problemas de encoding)  
✓ Headers de seguridad (HSTS, X-Frame-Options, etc.)  
✓ CORS configurado  
✓ Rate limiting en producción  
✓ Backups automáticos en RDS (7 días)

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

# Reconstruir imágenes
docker-compose build --no-cache
```

---

## 🆘 Soporte

### Problemas Comunes

**"No es seguro el sitio"**
- Configurar SSL con ACM + DuckDNS
- Usar HTTPS en lugar de HTTP

**"Error de encoding (AbogacÃa)"**
- Base de datos con utf8mb4
- Headers Content-Type: utf-8
- Ver CONFIGURACION_Y_DESPLIEGUE.md

**"No conecta a RDS"**
- Verificar endpoint en .env
- Revisar Security Group
- Verificar contraseña

**"Certificado inválido"**
- Esperar validación ACM (10-15 min)
- Validar en DuckDNS
- Limpiar caché del navegador

---

## 🔗 Enlaces Útiles

- **AWS Educate**: https://aws.amazon.com/education/awseducate/
- **DuckDNS**: https://www.duckdns.org/
- **Docker**: https://www.docker.com/
- **Flask**: https://flask.palletsprojects.com/
- **NGINX**: https://nginx.org/

---

## 📝 Autores

**Cristian Cabarcas** **David Ruiz** **David Quintero**- EAFIT 2025  
Práctica Final - Internet: Arquitectura y Protocolos

