# Guía de Despliegue en AWS

## Tabla de Contenidos
1. [Preparación Inicial](#preparación-inicial)
2. [Paso 1: Configurar AWS CLI](#paso-1-configurar-aws-cli)
3. [Paso 2: Crear ECR (Elastic Container Registry)](#paso-2-crear-ecr)
4. [Paso 3: Subir Imágenes a ECR](#paso-3-subir-imágenes-a-ecr)
5. [Paso 4: Crear Base de Datos RDS](#paso-4-crear-base-de-datos-rds)
6. [Paso 5: Crear ECS Cluster](#paso-5-crear-ecs-cluster)
7. [Paso 6: Crear Application Load Balancer](#paso-6-crear-application-load-balancer)
8. [Paso 7: Registrar Dominio en Route 53](#paso-7-registrar-dominio-en-route-53)
9. [Paso 8: Verificar Despliegue](#paso-8-verificar-despliegue)

---

## Preparación Inicial

### Requisitos:
- Cuenta AWS activa (Amazon Educate recomendado)
- AWS CLI instalado y configurado
- Docker instalado localmente
- Acceso a AWS Management Console
- Un nombre de dominio (registrable en Route 53 o transferible)

### Instalaciones Necesarias:
```powershell
# Instalar AWS CLI (si no lo tiene)
choco install awscli

# Configurar AWS CLI
aws configure
# Ingrese: Access Key, Secret Access Key, Default Region (us-east-1 recomendado)

# Verificar instalación
aws sts get-caller-identity
```

---

## Paso 1: Configurar AWS CLI

```powershell
# Configurar credenciales (ejecutar en terminal)
aws configure

# Ingrese los siguientes valores:
# AWS Access Key ID: [Tu Access Key]
# AWS Secret Access Key: [Tu Secret Key]
# Default region name: us-east-1
# Default output format: json

# Verificar configuración
aws ec2 describe-regions --query 'Regions[0]'
```

---

## Paso 2: Crear ECR (Elastic Container Registry)

### Opción A: Usar AWS Console

1. Ve a **Amazon ECR** → **Repositorios**
2. Haz clic en **Crear repositorio**
3. Crea 3 repositorios:
   - `practicafinal-web-es`
   - `practicafinal-web-en`
   - `practicafinal-stats`

### Opción B: Usar AWS CLI

```powershell
# Crear repositorios
aws ecr create-repository --repository-name practicafinal-web-es --region us-east-1
aws ecr create-repository --repository-name practicafinal-web-en --region us-east-1
aws ecr create-repository --repository-name practicafinal-stats --region us-east-1

# Ver URI de repositorio
aws ecr describe-repositories --repository-names practicafinal-web-es --region us-east-1 --query 'repositories[0].repositoryUri'
```

---

## Paso 3: Subir Imágenes a ECR

### 1. Obtener Token de Login

```powershell
# Login en ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin [ACCOUNT_ID].dkr.ecr.us-east-1.amazonaws.com

# Obtener ACCOUNT_ID
$ACCOUNT_ID = aws sts get-caller-identity --query 'Account' --output text
Write-Host "Account ID: $ACCOUNT_ID"
```

### 2. Construir y Etiquetar Imágenes

```powershell
# Ir al directorio del proyecto
cd "d:\Users\Cristian\Documents\Visual Projects\PracticaFinal"

# Variables
$ACCOUNT_ID = aws sts get-caller-identity --query 'Account' --output text
$REGION = "us-east-1"
$ECR_REGISTRY = "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Construir imágenes locales
docker-compose build

# Etiquetar imágenes para ECR
docker tag practicafinal-web-es:latest "$ECR_REGISTRY/practicafinal-web-es:latest"
docker tag practicafinal-web-en:latest "$ECR_REGISTRY/practicafinal-web-en:latest"
docker tag practicafinal-stats:latest "$ECR_REGISTRY/practicafinal-stats:latest"

# Subir a ECR
docker push "$ECR_REGISTRY/practicafinal-web-es:latest"
docker push "$ECR_REGISTRY/practicafinal-web-en:latest"
docker push "$ECR_REGISTRY/practicafinal-stats:latest"
```

---

## Paso 4: Crear Base de Datos RDS

### 1. Crear DB Subnet Group

```powershell
# Crear subnet group (ejecutar una sola vez)
aws rds create-db-subnet-group `
  --db-subnet-group-name eafit-db-subnet `
  --db-subnet-group-description "Subnet group for EAFIT database" `
  --subnet-ids subnet-xxxxx subnet-yyyyy `
  --region us-east-1
```

### 2. Crear Instancia RDS MySQL

```powershell
$DB_PASSWORD = "EafitDB2025Secure!" # Cambiar contraseña

aws rds create-db-instance `
  --db-instance-identifier eafit-mysql-db `
  --db-instance-class db.t3.micro `
  --engine mysql `
  --engine-version 8.0.35 `
  --master-username admin `
  --master-user-password $DB_PASSWORD `
  --allocated-storage 20 `
  --db-subnet-group-name eafit-db-subnet `
  --publicly-accessible true `
  --storage-type gp3 `
  --multi-az false `
  --backup-retention-period 7 `
  --region us-east-1

Write-Host "Contraseña guardada: $DB_PASSWORD"
Write-Host "Guarde esta contraseña en un lugar seguro"
```

### 3. Esperar a que RDS esté disponible

```powershell
# Ver estado de DB
aws rds describe-db-instances `
  --db-instance-identifier eafit-mysql-db `
  --region us-east-1 `
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]'

# Esperar hasta que muestre: "available"
# Esto puede tomar 5-10 minutos
```

### 4. Inicializar Base de Datos

```powershell
# Una vez disponible, conectarse y ejecutar init script
$DB_HOST = aws rds describe-db-instances `
  --db-instance-identifier eafit-mysql-db `
  --region us-east-1 `
  --query 'DBInstances[0].Endpoint.Address' `
  --output text

Write-Host "DB Host: $DB_HOST"

# Conectarse con MySQL Workbench o línea de comandos:
# mysql -h $DB_HOST -u admin -p
# Luego ejecutar: cat ./database/init.sql
```

---

## Paso 5: Crear ECS Cluster

### 1. Crear Cluster

```powershell
# Crear cluster de ECS
aws ecs create-cluster `
  --cluster-name eafit-cluster `
  --region us-east-1

# Ver clusters
aws ecs list-clusters --region us-east-1
```

### 2. Crear Task Definition

Editar y crear archivo `ecs-task-definition.json`:

```json
{
  "family": "eafit-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "web-es",
      "image": "[ACCOUNT_ID].dkr.ecr.us-east-1.amazonaws.com/practicafinal-web-es:latest",
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 5000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DB_HOST",
          "value": "[RDS_ENDPOINT]"
        },
        {
          "name": "DB_USER",
          "value": "admin"
        },
        {
          "name": "DB_PASSWORD",
          "value": "[DB_PASSWORD]"
        },
        {
          "name": "DB_NAME",
          "value": "usuarios"
        },
        {
          "name": "LANGUAGE",
          "value": "es"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/eafit-web-es",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### 3. Registrar Task Definition

```powershell
# Editar ecs-task-definition.json con valores reales
aws ecs register-task-definition `
  --cli-input-json file://ecs-task-definition.json `
  --region us-east-1
```

---

## Paso 6: Crear Application Load Balancer

### 1. Crear Security Group para ALB

```powershell
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text

aws ec2 create-security-group `
  --group-name eafit-alb-sg `
  --description "Security group for EAFIT ALB" `
  --vpc-id $VPC_ID `
  --region us-east-1

$ALB_SG_ID = aws ec2 describe-security-groups `
  --filters "Name=group-name,Values=eafit-alb-sg" `
  --query 'SecurityGroups[0].GroupId' `
  --output text

# Permitir HTTP y HTTPS
aws ec2 authorize-security-group-ingress `
  --group-id $ALB_SG_ID `
  --protocol tcp `
  --port 80 `
  --cidr 0.0.0.0/0 `
  --region us-east-1

aws ec2 authorize-security-group-ingress `
  --group-id $ALB_SG_ID `
  --protocol tcp `
  --port 443 `
  --cidr 0.0.0.0/0 `
  --region us-east-1

Write-Host "ALB Security Group ID: $ALB_SG_ID"
```

### 2. Crear Application Load Balancer

```powershell
# Obtener subnet IDs
$SUBNET_IDS = aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query 'Subnets[0:2].SubnetId' `
  --output text

$SUBNETS = $SUBNET_IDS -split ' ' | Select-Object -First 2

aws elbv2 create-load-balancer `
  --name eafit-alb `
  --subnets $SUBNETS `
  --security-groups $ALB_SG_ID `
  --scheme internet-facing `
  --type application `
  --region us-east-1

$ALB_ARN = aws elbv2 describe-load-balancers `
  --names eafit-alb `
  --query 'LoadBalancers[0].LoadBalancerArn' `
  --output text

Write-Host "ALB ARN: $ALB_ARN"
```

### 3. Crear Target Groups

```powershell
$TG_ES = aws elbv2 create-target-group `
  --name eafit-tg-es `
  --protocol HTTP `
  --port 5000 `
  --vpc-id $VPC_ID `
  --target-type ip `
  --query 'TargetGroups[0].TargetGroupArn' `
  --output text

Write-Host "Target Group ES: $TG_ES"
```

---

## Paso 7: Registrar Dominio en Route 53

### 1. Crear Hosted Zone

```powershell
# Buscar dominio disponible o transferir uno existente
# https://console.aws.amazon.com/route53/

# Crear hosted zone
aws route53 create-hosted-zone `
  --name tudominio.com `
  --caller-reference "$(Get-Date -Format 'yyyyMMddHHmmss')" `
  --region us-east-1
```

### 2. Crear Registro A

```powershell
# Obtener DNS del ALB
$ALB_DNS = aws elbv2 describe-load-balancers `
  --load-balancer-arns $ALB_ARN `
  --query 'LoadBalancers[0].DNSName' `
  --output text

Write-Host "ALB DNS: $ALB_DNS"

# Obtener Hosted Zone ID
$HOSTED_ZONE_ID = aws route53 list-hosted-zones-by-name `
  --query 'HostedZones[0].Id' `
  --output text | ForEach-Object { $_ -split '/' | Select-Object -Last 1 }

# Crear registro A
aws route53 change-resource-record-sets `
  --hosted-zone-id $HOSTED_ZONE_ID `
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "tudominio.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z35SXDOTRQ7X7K",
          "DNSName": "'$ALB_DNS'",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }' `
  --region us-east-1
```

---

## Paso 8: Verificar Despliegue

### 1. Verificar que servicios estén activos

```powershell
# Verificar ALB
aws elbv2 describe-load-balancers --names eafit-alb --region us-east-1

# Verificar ECS
aws ecs describe-clusters --clusters eafit-cluster --region us-east-1

# Verificar RDS
aws rds describe-db-instances --db-instance-identifier eafit-mysql-db --region us-east-1
```

### 2. Probar la aplicación

```
HTTP: http://[ALB_DNS]/es
HTTPS: https://tudominio.com/es (después de certificado SSL)
```

---

## Configuración SSL/TLS con AWS Certificate Manager

### 1. Solicitar Certificado

```powershell
aws acm request-certificate `
  --domain-name tudominio.com `
  --subject-alternative-names "*.tudominio.com" `
  --validation-method DNS `
  --region us-east-1
```

### 2. Validar Certificado

- Ir a **AWS Certificate Manager**
- Validar dominios mediante registros DNS en Route 53
- Esperar validación (puede tomar minutos)

### 3. Agregar HTTPS al ALB

```powershell
# Obtener Certificate ARN
$CERT_ARN = aws acm list-certificates --region us-east-1 --query 'CertificateSummaryList[0].CertificateArn' --output text

# Crear listener HTTPS
aws elbv2 create-listener `
  --load-balancer-arn $ALB_ARN `
  --protocol HTTPS `
  --port 443 `
  --certificates CertificateArn=$CERT_ARN `
  --default-actions Type=forward,TargetGroupArn=$TG_ES `
  --region us-east-1
```

---

## Costos Estimados (Educate Tier)

| Servicio | Costo Mensual | Notas |
|----------|---------------|-------|
| ALB | $16.20 | Horas + procesamiento de datos |
| ECS Fargate | $10-20 | Basado en CPU/Memory |
| RDS MySQL | $9.50 | db.t3.micro con almacenamiento 20GB |
| Route 53 | $0.50 | Hosted zone |
| **Total Aproximado** | **$35-45** | Puede variar |

---

## Comandos Útiles

```powershell
# Ver logs de ECS
aws logs get-log-events `
  --log-group-name /ecs/eafit-web-es `
  --log-stream-name ecs/web-es/[TASK_ID] `
  --region us-east-1

# Escalar servicios
aws ecs update-service `
  --cluster eafit-cluster `
  --service eafit-service `
  --desired-count 3 `
  --region us-east-1

# Eliminar recursos (CUIDADO)
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
aws rds delete-db-instance --db-instance-identifier eafit-mysql-db --skip-final-snapshot
aws ecs delete-cluster --cluster eafit-cluster
```

---

## Soporte y Recursos

- **AWS Free Tier**: https://aws.amazon.com/free/
- **AWS Educate**: https://aws.amazon.com/education/awseducate/
- **ECS Documentation**: https://docs.aws.amazon.com/ecs/
- **RDS Documentation**: https://docs.aws.amazon.com/rds/

---

**Última actualización**: Mayo 24, 2026
