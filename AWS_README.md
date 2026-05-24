# Despliegue en AWS con DuckDNS

## Descripción General

Este proyecto está configurado para desplegarse en **AWS** utilizando:
- **ECR** para imágenes Docker
- **ECS Fargate** para contenedores
- **RDS MySQL** para base de datos
- **Application Load Balancer** para balanceo de carga
- **DuckDNS** para dominio dinámico (GRATIS)
- **ACM** para certificados SSL/TLS

---

## Documentación

### 📋 Documentos Principales

1. **`CONFIGURACION_Y_DESPLIEGUE.md`** - LEER PRIMERO
   - Requisitos del sistema
   - Arquitectura del servicio
   - Componentes principales
   - Guía completa de despliegue
   - Configuración DuckDNS
   - Testing y troubleshooting

2. **`aws-deploy.ps1`** - Script de automatización
   - Setup automatizado de todos los recursos
   - Comandos individuales por componente
   - Verificación de estado

3. **`.env.aws.example`** - Variables de configuración
   - Base de datos
   - SMTP
   - AWS

4. **`ecs-task-definition.json`** - Definición de tareas ECS
   - Configuración de contenedores
   - Variables de entorno
   - Health checks

5. **`init-rds.sh`** - Script inicialización de BD
   - Crear base de datos
   - Crear tabla de registros
   - Insertar datos de prueba

---

## Quick Start (5 minutos)

### 1. Configurar AWS CLI

```powershell
choco install awscli
aws configure
aws sts get-caller-identity
```

### 2. Desplegar (Automatizado)

```powershell
cd "d:\Users\Cristian\Documents\Visual Projects\PracticaFinal"
.\aws-deploy.ps1 -Action setup-all
```

### 3. Configurar DuckDNS

1. Ir a https://www.duckdns.org
2. Crear dominio (ej: `miapp`)
3. Obtener IP del ALB
4. Apuntar dominio al ALB
5. Esperar propagación DNS (5-10 min)

### 4. Acceder a la Aplicación

```
http://miapp.duckdns.org/es
https://miapp.duckdns.org/es (con SSL)
https://miapp.duckdns.org/stats?password=admin123
```

---

## Costos

| Componente | Costo | Con AWS Educate |
|-----------|-------|-----------------|
| ALB | $16.20/mes | Gratis |
| ECS | $15-25/mes | Gratis |
| RDS | $9.50/mes | Gratis |
| DuckDNS | $0 | Gratis |
| **Total** | **~$41** | **$0 (crédito $100)** |

---

## Archivos de Configuración

### `.env` (Local)
```env
DB_HOST=db
DB_USER=root
DB_PASSWORD=eafit_2025_secure
DB_NAME=usuarios
SMTP_USER=tu-email@gmail.com
SMTP_PASSWORD=tu-app-password
```

### `.env.aws` (Producción)
```env
DB_HOST=[RDS_ENDPOINT]
DB_USER=admin
DB_PASSWORD=[RDS_PASSWORD]
SMTP_USER=[TU_GMAIL]
SMTP_PASSWORD=[APP_PASSWORD]
```

---

## Verificación

```powershell
# Verificar recursos AWS
aws ecr describe-repositories --region us-east-1
aws rds describe-db-instances --db-instance-identifier eafit-mysql-db --region us-east-1
aws ecs list-clusters --region us-east-1
aws elbv2 describe-load-balancers --names eafit-alb --region us-east-1

# Obtener info necesaria
$ALB_DNS = aws elbv2 describe-load-balancers --names eafit-alb --region us-east-1 --query 'LoadBalancers[0].DNSName' --output text
Write-Host "ALB DNS: $ALB_DNS"
```

---

## Recursos

- **AWS Console**: https://console.aws.amazon.com/
- **AWS Educate**: https://aws.amazon.com/education/awseducate/
- **DuckDNS**: https://www.duckdns.org/
- **Documentación Completa**: Ver `CONFIGURACION_Y_DESPLIEGUE.md`

---

**Última actualización**: Mayo 24, 2026  
**Versión**: 1.0
