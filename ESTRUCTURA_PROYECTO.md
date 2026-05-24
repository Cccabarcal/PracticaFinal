
# 📁 Estructura del Proyecto - Resumen Visual

```
PracticaFinal/
│
├── 📄 README.md                      ← Documentación principal (LEER PRIMERO)
├── 📄 DOCUMENTACION_TECNICA.md       ← Detalles técnicos de cada componente
├── 📄 DESPLIEGUE_AWS.md              ← Paso a paso para AWS
├── 📄 GUIA_SUSTENTACION.md           ← Cómo presentar el proyecto
├── 📄 COMANDOS_UTILES.md             ← Referencia rápida de comandos
├── 📄 TESTING.md                     ← Plan de pruebas
│
├── 📜 docker-compose.yml             ← Orquestación de contenedores
├── 📜 Makefile                       ← Comandos útiles (make help)
├── 📜 .env.example                   ← Plantilla de variables de entorno
├── 📜 .gitignore                     ← Archivos ignorados por git
│
├── 📂 app-web/                       ← Aplicación web principal
│   ├── 🐍 app.py                    ← Código Flask (rutas, lógica)
│   ├── 📄 Dockerfile                ← Imagen Docker para web
│   ├── 📜 requirements.txt           ← Dependencias Python
│   ├── 📜 .dockerignore              ← Archivos ignorados en imagen
│   │
│   └── 📂 templates/                 ← Plantillas HTML
│       ├── 🌐 index_es.html          ← Formulario en español
│       └── 🌐 index_en.html          ← Formulario en inglés
│
├── 📂 app-estadisticas/             ← Aplicación de reportes
│   ├── 🐍 app.py                    ← Código Flask (estadísticas, correos)
│   ├── 📄 Dockerfile                ← Imagen Docker para stats
│   ├── 📜 requirements.txt           ← Dependencias Python
│   ├── 📜 .dockerignore              ← Archivos ignorados en imagen
│   │
│   └── 📂 templates/                 ← Plantillas HTML
│       └── 🌐 dashboard.html         ← Dashboard con gráficas
│
├── 📂 nginx/                         ← Configuración del balanceador
│   └── 📜 nginx.conf                 ← Configuración NGINX (proxy + SSL)
│
├── 📂 database/                      ← Scripts de base de datos
│   ├── 📜 init.sql                   ← Inicialización de BD
│   └── 📜 .dockerignore              ← Archivos ignorados
│
├── 📂 certs/                         ← Certificados SSL
│   ├── 🔒 server.crt                 ← Certificado público
│   └── 🔒 server.key                 ← Clave privada
│
├── 🔧 generate_certs.sh              ← Script para generar certs (Linux/Mac)
└── 🔧 generate_certs.ps1             ← Script para generar certs (Windows)
```

---

## 🎯 Componentes Principales

### 1️⃣ Aplicación Web (Flask)
- **Ubicación**: `app-web/`
- **Versiones**: Español (web-es) e Inglés (web-en)
- **Puerto**: 5000
- **Funciones**:
  - Mostrar formulario de registro
  - Validar y guardar datos
  - Conectar con base de datos

### 2️⃣ Balanceador de Carga (NGINX)
- **Ubicación**: `nginx/`
- **Puertos**: 80 (HTTP), 443 (HTTPS)
- **Funciones**:
  - Distribuir tráfico (Round Robin)
  - Actuar como proxy inverso
  - Manejar SSL/TLS
  - Headers de seguridad

### 3️⃣ Base de Datos (MySQL)
- **Ubicación**: `database/`
- **Puerto**: 3306
- **Tabla**: `registros`
- **Campos**: nombre, comuna, carrera, fecha

### 4️⃣ Estadísticas (Flask)
- **Ubicación**: `app-estadisticas/`
- **Puerto**: 5001
- **Funciones**:
  - Dashboard con gráficas
  - Análisis de datos
  - Envío de correos

---

## 🔄 Flujo de Datos

```
                    ┌─────────────────────────────────┐
                    │      Internet / Usuario         │
                    │        HTTPS :443               │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────┴──────────────────┐
                    │        NGINX                    │
                    │  (Balanceador + Proxy)          │
                    │  (SSL/TLS, Round Robin)         │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────┴───────────────────┐
                    │                                  │
        ┌───────────▼─────────┐        ┌──────────────▼────────────┐
        │   WEB-ES (Flask)    │        │   WEB-EN (Flask)          │
        │   Puerto 5000       │        │   Puerto 5000             │
        │   Español           │        │   Inglés                  │
        └───────────┬─────────┘        └──────────────┬────────────┘
                    │                                  │
                    └──────────────┬───────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │    MySQL Database               │
                    │    Puerto 3306                  │
                    │    Tabla: registros             │
                    └─────────────────────────────────┘

                    ┌─────────────────────────────────┐
                    │   ESTADÍSTICAS (Flask)          │
                    │   Puerto 5001                   │
                    │   Dashboard + Gráficas + Email  │
                    └─────────────────────────────────┘
```

---

## 📦 Tecnologías Utilizadas

| Componente | Tecnología | Versión |
|-----------|-----------|---------|
| Servidor Web | Python + Flask | 3.11 + 3.0.0 |
| Proxy/Balanceador | NGINX | 1.25 Alpine |
| Base de Datos | MySQL | 8.0 |
| WSGI Server | Gunicorn | 21.2.0 |
| Contenedor | Docker | Latest |
| Orquestación | Docker Compose | 3.9 |

---

## 🚀 Ciclo de Vida de una Solicitud

```
1. Usuario accede a https://localhost/es
   ↓
2. NGINX recibe en puerto 443 (HTTPS)
   ↓
3. NGINX valida certificado SSL
   ↓
4. NGINX balancea a web-es o web-en (Round Robin)
   ↓
5. Flask procesa la solicitud
   ↓
6. Si es POST /register:
   - Valida datos
   - Conecta a MySQL
   - Inserta registro
   - Retorna respuesta JSON
   ↓
7. NGINX retorna respuesta al cliente
   ↓
8. Navegador del usuario muestra resultado
```

---

## 📊 Base de Datos - Esquema

```sql
registros (tabla)
├── id (INT, PRIMARY KEY, AUTO_INCREMENT)
├── nombre (VARCHAR 255)
├── comuna (VARCHAR 100)
├── carrera (VARCHAR 100)
├── fecha (DATETIME)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)

Índices:
├── idx_comuna
├── idx_carrera
└── idx_fecha
```

---

## 🔐 Seguridad - Capas

```
┌─────────────────────────────────────────┐
│  HTTPS / SSL-TLS                        │
│  (Encriptación en tránsito)             │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│  Headers de Seguridad                   │
│  (Strict-Transport-Security, etc)       │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│  Validación de Datos                    │
│  (Cliente y servidor)                   │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│  Contraseña de Administrador             │
│  (Para acceso a reportes)                │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│  Red Privada Docker                      │
│  (Base de datos aislada)                │
└─────────────────────────────────────────┘
```

---

## 📈 Escalabilidad

```
Desarrollo (Actual)
├── 1 Instancia
├── 2 Servidores Web
├── 1 Base de Datos
└── 1 Balanceador

Producción (AWS)
├── Auto Scaling Group (EC2)
├── N Servidores Web
├── RDS (Replicación multi-AZ)
├── Load Balancer (ALB/NLB)
├── CloudFront (CDN)
└── CloudWatch (Monitoreo)
```

---

## 🎯 Endpoints Principales

| URL | Método | Descripción |
|-----|--------|-------------|
| `/es` | GET | Formulario en español |
| `/en` | GET | Formulario en inglés |
| `/register` | POST | Registrar usuario |
| `/stats` | GET | Dashboard de estadísticas |
| `/api/statistics` | GET | Estadísticas en JSON |
| `/api/send-report` | POST | Enviar reporte por correo |
| `/health` | GET | Health check |

---

## 📚 Archivos Clave

| Archivo | Propósito |
|---------|-----------|
| `docker-compose.yml` | Define todos los servicios |
| `nginx.conf` | Configuración del balanceador |
| `app.py` (web) | Lógica de formulario |
| `app.py` (stats) | Lógica de reportes |
| `init.sql` | Estructura de BD |
| `requirements.txt` | Dependencias Python |
| `Dockerfile` | Definición de imágenes |

---

## ⚡ Comandos Rápidos

```bash
# Instalación
cp .env.example .env
bash generate_certs.sh
docker-compose up -d

# Desarrollo
docker-compose logs -f
docker-compose ps

# Testing
curl -k https://localhost/es
make test

# Limpieza
docker-compose down -v
```

---

## 📅 Línea de Tiempo de Implementación

```
Día 1: Instalación y configuración
├── Docker Compose
├── Variables de entorno
└── Generación de certificados

Día 2: Desarrollo de aplicación web
├── Rutas Flask
├── Templates HTML
├── Conexión a BD
└── Validación

Día 3: Aplicación de estadísticas
├── Dashboard
├── Gráficas
├── Email
└── Análisis

Día 4: Configuración NGINX
├── Proxy inverso
├── Balanceo round robin
├── SSL/TLS
└── Headers de seguridad

Día 5: Testing y documentación
├── Pruebas funcionales
├── Pruebas de carga
├── Documentación técnica
└── Guía de despliegue

Día 6-7: Despliegue en AWS
├── Instancia EC2
├── Configuración de dominio
├── Let's Encrypt
└── Pruebas finales
```

---

¡Todo listo para desarrollar y desplegar! 🚀
