# Configuración y Despliegue del Servicio - EAFIT PracticaFinal

## Tabla de Contenidos
1. [Requisitos del Sistema](#requisitos-del-sistema)
2. [Arquitectura del Servicio](#arquitectura-del-servicio)
3. [Componentes Principales](#componentes-principales)
4. [Configuración Local](#configuración-local)
5. [Despliegue en AWS](#despliegue-en-aws)
6. [Configuración del Dominio con DuckDNS](#configuración-del-dominio-con-duckdns)
7. [Verificación y Testing](#verificación-y-testing)

---

## Requisitos del Sistema

### Hardware
- Servidor con mínimo 2 vCPU y 4GB RAM (para desarrollo local)
- AWS EC2 (t3.medium o superior para producción)

### Software
- Docker 20.10+
- Docker Compose 2.0+
- AWS CLI 2.0+
- Python 3.11+
- MySQL 8.0+
- Node.js 18+ (opcional, para herramientas frontend)

### Servicios Externos
- Cuenta AWS (Amazon Educate recomendado)
- Dominio DuckDNS (https://www.duckdns.org) - GRATIS
- Cuenta Gmail con contraseña de aplicación para SMTP

---

## Arquitectura del Servicio

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET (HTTPS)                      │
│              duckdns-domain.duckdns.org:443                  │
└────────────────────────────┬────────────────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │  DuckDNS (DNS)   │ ─────► tudominio.duckdns.org
                    └────────┬─────────┘        (redirección DNS)
                             │
                    ┌────────▼──────────┐
                    │ AWS ALB (443/80)  │
                    │ Load Balancer     │
                    └────────┬──────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
      ┌────▼──────┐  ┌───────▼────────┐  ┌────▼──────┐
      │  web-es   │  │  web-en        │  │ stats     │
      │  (Flask)  │  │  (Flask)       │  │ (Flask)   │
      │ :5000     │  │  :5000         │  │ :5001     │
      └────┬──────┘  └────────┬───────┘  └────┬──────┘
           │                  │                │
           └──────────────────┼────────────────┘
                              │
                    ┌─────────▼────────┐
                    │  RDS MySQL 8.0   │
                    │  (base de datos) │
                    │  db.t3.micro     │
                    └──────────────────┘
```

---

## Componentes Principales

### 1. **Servidor Web de Registro (app-web)**
- **Framework**: Flask 3.0.0
- **Puertos**: 5000 (HTTP interno)
- **Versiones**: 
  - web-es (Spanish)
  - web-en (English)
- **Función**: Formulario de registro de estudiantes
- **Servidor**: Gunicorn 4 workers, 120s timeout

### 2. **Servidor de Estadísticas (app-estadisticas)**
- **Framework**: Flask 3.0.0
- **Puerto**: 5001 (HTTP interno)
- **Función**: Dashboard de estadísticas y envío de reportes por email
- **Visualización**: Gráficos con Matplotlib 3.8.2
- **Email**: SMTP con Gmail (configurado en .env)

### 3. **Proxy Inverso y Balanceador (NGINX)**
- **Versión**: 1.25-alpine
- **Puertos**: 
  - 80 (HTTP)
  - 443 (HTTPS con certificado)
- **Funciones**:
  - Balanceo de carga (round robin)
  - Proxy inverso
  - Terminación SSL/TLS
  - Headers de seguridad

### 4. **Base de Datos (MySQL)**
- **Versión**: 8.0
- **Charset**: utf8mb4 (soporte completo de caracteres acentuados)
- **Tabla**: `registros` (id, nombre, comuna, carrera, fecha, timestamps)
- **Almacenamiento**: Volumen persistente (db_data)

---

## Configuración Local

### 1. Clonar o Descargar Proyecto

```bash
cd "d:\Users\Cristian\Documents\Visual Projects\PracticaFinal"
```

### 2. Configurar Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar .env con tus valores
# Variables principales:
# DB_HOST=db
# DB_USER=root
# DB_PASSWORD=eafit_2025_secure
# DB_NAME=usuarios
# ADMIN_PASSWORD=admin123
# SMTP_USER=tu-email@gmail.com
# SMTP_PASSWORD=tu-app-password
```

### 3. Iniciar Servicios Localmente

```bash
# Construir imágenes
docker-compose build

# Iniciar servicios
docker-compose up -d

# Verificar que estén corriendo
docker-compose ps

# Ver logs
docker-compose logs -f
```

### 4. Acceder a la Aplicación Local

- **Español**: http://localhost/es
- **Inglés**: http://localhost/en
- **Estadísticas**: http://localhost/stats?password=admin123

---

## Despliegue en AWS

### Opción 1: Despliegue Automatizado (Recomendado)

```powershell
# Ejecutar script de despliegue
.\aws-deploy.ps1 -Action setup-all

# Verificar estado
.\aws-deploy.ps1 -Action status
```

### Opción 2: Despliegue Manual

#### Paso 1: Preparar ECR

```powershell
# Instalar AWS CLI
choco install awscli

# Configurar credenciales
aws configure

# Crear repositorios ECR
aws ecr create-repository --repository-name practicafinal-web-es --region us-east-1
aws ecr create-repository --repository-name practicafinal-web-en --region us-east-1
aws ecr create-repository --repository-name practicafinal-stats --region us-east-1
```

#### Paso 2: Subir Imágenes Docker

```powershell
$ACCOUNT_ID = aws sts get-caller-identity --query 'Account' --output text
$ECR_REGISTRY = "$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# Login ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Construir y subir imágenes
docker-compose build
docker tag practicafinal-web-es:latest "$ECR_REGISTRY/practicafinal-web-es:latest"
docker tag practicafinal-web-en:latest "$ECR_REGISTRY/practicafinal-web-en:latest"
docker tag practicafinal-stats:latest "$ECR_REGISTRY/practicafinal-stats:latest"

docker push "$ECR_REGISTRY/practicafinal-web-es:latest"
docker push "$ECR_REGISTRY/practicafinal-web-en:latest"
docker push "$ECR_REGISTRY/practicafinal-stats:latest"
```

#### Paso 3: Crear Base de Datos RDS

```powershell
$DB_PASSWORD = "EafitDB2025Secure!"

# Crear instancia RDS
aws rds create-db-instance `
  --db-instance-identifier eafit-mysql-db `
  --db-instance-class db.t3.micro `
  --engine mysql `
  --engine-version 8.0.35 `
  --master-username admin `
  --master-user-password $DB_PASSWORD `
  --allocated-storage 20 `
  --publicly-accessible true `
  --region us-east-1

# Esperar disponibilidad (5-10 minutos)
aws rds describe-db-instances --db-instance-identifier eafit-mysql-db --region us-east-1 --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]'
```

#### Paso 4: Crear ECS Cluster

```powershell
# Crear cluster
aws ecs create-cluster --cluster-name eafit-cluster --region us-east-1

# Registrar task definition
aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --region us-east-1
```

#### Paso 5: Crear ALB

```powershell
# Crear security group
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text

$ALB_SG = aws ec2 create-security-group `
  --group-name eafit-alb-sg `
  --description "ALB Security Group" `
  --vpc-id $VPC_ID `
  --query 'GroupId' `
  --output text

# Permitir puertos
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 443 --cidr 0.0.0.0/0

# Crear ALB
$SUBNETS = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0:2].SubnetId' --output text

aws elbv2 create-load-balancer `
  --name eafit-alb `
  --subnets $SUBNETS.Split() `
  --security-groups $ALB_SG `
  --scheme internet-facing `
  --type application `
  --region us-east-1

# Crear target group
aws elbv2 create-target-group `
  --name eafit-tg-es `
  --protocol HTTP `
  --port 5000 `
  --vpc-id $VPC_ID `
  --target-type ip `
  --region us-east-1
```

---

## Configuración del Dominio con DuckDNS

### ¿Por qué DuckDNS?
- **Gratis**: Sin costo
- **Fácil**: Configuración simple en minutos
- **Dinámico**: Actualiza automáticamente tu IP
- **HTTPS**: Soporte para certificados SSL
- **Confiable**: Servicio estable desde 2010

### Paso 1: Registrarse en DuckDNS

1. Ir a https://www.duckdns.org
2. Hacer click en "Sign in"
3. Autenticarse con GitHub/Google (recomendado)
4. Aceptar permisos

### Paso 2: Crear Dominio

1. En el dashboard de DuckDNS
2. Crear nuevo dominio (ej: `miapp`)
3. Tu dominio será: `miapp.duckdns.org`
4. Guardar el **token** (necesario para actualizaciones)

### Paso 3: Apuntar a ALB

```powershell
# Obtener DNS del ALB
$ALB_DNS = aws elbv2 describe-load-balancers `
  --names eafit-alb `
  --region us-east-1 `
  --query 'LoadBalancers[0].DNSName' `
  --output text

Write-Host "ALB DNS: $ALB_DNS"
```

En DuckDNS dashboard:
1. Seleccionar el dominio creado
2. En "IP" ingresar el DNS del ALB (sin https://)
3. Hacer click en "update ip"
4. Esperar 5-10 minutos para propagación DNS

### Paso 4: Obtener Certificado SSL

```powershell
# Solicitar certificado en ACM
aws acm request-certificate `
  --domain-name miapp.duckdns.org `
  --subject-alternative-names "*.miapp.duckdns.org" `
  --validation-method DNS `
  --region us-east-1

# Validar en Route 53 o manualmente
# Una vez validado, obtener ARN del certificado
$CERT_ARN = aws acm list-certificates --region us-east-1 --query 'CertificateSummaryList[0].CertificateArn' --output text
```

### Paso 5: Crear Listener HTTPS en ALB

```powershell
$ALB_ARN = aws elbv2 describe-load-balancers --names eafit-alb --region us-east-1 --query 'LoadBalancers[0].LoadBalancerArn' --output text
$TG_ARN = aws elbv2 describe-target-groups --names eafit-tg-es --region us-east-1 --query 'TargetGroups[0].TargetGroupArn' --output text

aws elbv2 create-listener `
  --load-balancer-arn $ALB_ARN `
  --protocol HTTPS `
  --port 443 `
  --certificates CertificateArn=$CERT_ARN `
  --default-actions Type=forward,TargetGroupArn=$TG_ARN `
  --region us-east-1
```

---

## Verificación y Testing

### Verificar Recursos en AWS

```powershell
# ECR
aws ecr describe-repositories --region us-east-1

# RDS
aws rds describe-db-instances --db-instance-identifier eafit-mysql-db --region us-east-1

# ECS
aws ecs list-clusters --region us-east-1
aws ecs describe-services --cluster eafit-cluster --services eafit-service --region us-east-1

# ALB
aws elbv2 describe-load-balancers --names eafit-alb --region us-east-1
```

### Pruebas de Aplicación

```bash
# Registrar un usuario
curl -X POST http://miapp.duckdns.org/register \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Test User",
    "comuna": "Comuna 1",
    "carrera": "Ingeniería"
  }'

# Ver estadísticas
curl http://miapp.duckdns.org/stats?password=admin123

# Enviar reporte por email
curl -X POST http://miapp.duckdns.org/api/send-report \
  -H "Content-Type: application/json" \
  -d '{"email": "tu-correo@example.com"}' \
  -G --data-urlencode "password=admin123"
```

### Ver Logs

```powershell
# Logs de NGINX
aws logs tail /ecs/eafit-nginx --follow --region us-east-1

# Logs de aplicación
aws logs tail /ecs/eafit-web-es --follow --region us-east-1

# Logs de estadísticas
aws logs tail /ecs/eafit-stats --follow --region us-east-1
```

---

## Costos Estimados (AWS Educate)

| Componente | Costo/Mes | Con Educate |
|-----------|-----------|------------|
| ALB | $16.20 | Gratis |
| ECS Fargate | $15-25 | Gratis |
| RDS MySQL | $9.50 | Gratis |
| Certificado ACM | Gratis | Gratis |
| **Total** | **~$40** | **$0 (incluido)** |

**AWS Educate**: $100 USD/mes de crédito (suficiente para este proyecto)

---

## Troubleshooting

### Error: "No se puede conectar a ALB"
- Verificar Security Group permite puertos 80/443
- Verificar que servicios ECS estén ejecutándose
- Revisar logs con `docker-compose logs`

### Error: "Certificado inválido"
- Esperar a que ACM complete validación (10-15 min)
- Verificar registro DNS se creó correctamente
- Limpiar caché del navegador

### Error: "Base de datos no accesible"
- Verificar endpoint de RDS en variables de entorno
- Verificar contraseña es correcta
- Verificar Security Group de RDS permite conexión desde ECS

### DuckDNS no actualiza IP
- Verificar token de DuckDNS es correcto
- Esperar 5-10 minutos para propagación DNS
- Probar manualmente: `https://www.duckdns.org/update?domains=midominio&token=token&ip=ALB_IP`

---

## Seguridad

### Recomendaciones
- ✓ Usar HTTPS en producción (certificado ACM)
- ✓ Cambiar contraseña de admin
- ✓ Cambiar contraseña de RDS
- ✓ Usar app-specific password para Gmail SMTP
- ✓ Configurar backups automáticos en RDS
- ✓ Habilitar CloudWatch monitoring
- ✓ Revisar Security Groups regularmente

---

**Última actualización**: Mayo 24, 2026  
**Versión**: 1.0  
**Estado**: Producción Listo
