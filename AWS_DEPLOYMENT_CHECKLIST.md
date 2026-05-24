# Checklist de Despliegue en AWS

## ✓ Preparación Pre-Despliegue

- [ ] Cuenta AWS activa (preferible Amazon Educate)
- [ ] AWS CLI instalado y configurado
- [ ] Docker instalado localmente
- [ ] Acceso a AWS Management Console
- [ ] Nombre de dominio (registrable o transferible)
- [ ] Cuenta Gmail con contraseña de aplicación para SMTP

## ✓ Fase 1: Configuración Inicial (5 minutos)

### AWS CLI
- [ ] Instalar AWS CLI: `choco install awscli`
- [ ] Configurar credenciales: `aws configure`
- [ ] Ingresar Access Key y Secret Key
- [ ] Seleccionar región: `us-east-1`
- [ ] Verificar conexión: `aws sts get-caller-identity`

### Variantes de Ambiente
- [ ] Copiar `.env.aws.example` a `.env.aws`
- [ ] Completar valores en `.env.aws`
- [ ] Guardar contraseña de RDS de forma segura

## ✓ Fase 2: Crear Repositorios ECR (2 minutos)

- [ ] Crear repositorio `practicafinal-web-es`
- [ ] Crear repositorio `practicafinal-web-en`
- [ ] Crear repositorio `practicafinal-stats`
- [ ] Verificar repositorios creados

```powershell
aws ecr describe-repositories --region us-east-1
```

## ✓ Fase 3: Subir Imágenes Docker a ECR (10-15 minutos)

```powershell
# Login en ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin [ACCOUNT_ID].dkr.ecr.us-east-1.amazonaws.com

# Construir imágenes
docker-compose build

# Etiquetar imágenes
$ACCOUNT_ID = aws sts get-caller-identity --query 'Account' --output text
docker tag practicafinal-web-es:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/practicafinal-web-es:latest
docker tag practicafinal-web-en:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/practicafinal-web-en:latest
docker tag practicafinal-stats:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/practicafinal-stats:latest

# Subir imágenes
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/practicafinal-web-es:latest
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/practicafinal-web-en:latest
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/practicafinal-stats:latest
```

- [ ] Imágenes subidas a ECR
- [ ] Verificar en ECR Console

## ✓ Fase 4: Crear Base de Datos RDS (10-15 minutos)

- [ ] Crear Security Group para RDS
- [ ] Crear DB Subnet Group
- [ ] Crear instancia RDS MySQL
  - [ ] Instance: `eafit-mysql-db`
  - [ ] Class: `db.t3.micro`
  - [ ] Engine: MySQL 8.0
  - [ ] Master user: `admin`
  - [ ] Storage: 20 GB
  - [ ] Multi-AZ: No
  - [ ] Backup retention: 7 días

```powershell
# Esperar a que RDS esté disponible
aws rds describe-db-instances --db-instance-identifier eafit-mysql-db --region us-east-1 --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]'
```

- [ ] RDS disponible (status: "available")
- [ ] Obtener endpoint de RDS
- [ ] Ejecutar script de inicialización

```bash
bash init-rds.sh [RDS_HOST] admin [PASSWORD] usuarios
```

- [ ] Base de datos `usuarios` creada
- [ ] Tabla `registros` creada
- [ ] Datos de prueba insertados

## ✓ Fase 5: Crear ECS Cluster (3 minutos)

```powershell
aws ecs create-cluster --cluster-name eafit-cluster --region us-east-1
```

- [ ] Cluster `eafit-cluster` creado
- [ ] Verificar en ECS Console

## ✓ Fase 6: Crear Roles IAM (2 minutos)

```powershell
# Crear role para ECS Task Execution
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

# Adjuntar política
aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Crear role para ECS Task
aws iam create-role --role-name ecsTaskRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

# Adjuntar política para CloudWatch Logs
aws iam attach-role-policy --role-name ecsTaskRole --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
```

- [ ] Role `ecsTaskExecutionRole` creado
- [ ] Role `ecsTaskRole` creado
- [ ] Políticas adjuntadas

## ✓ Fase 7: Registrar Task Definition (2 minutos)

```powershell
# Editar ecs-task-definition.json
# Reemplazar:
#   [ACCOUNT_ID] con tu Account ID
#   [RDS_ENDPOINT_HERE] con endpoint de RDS
#   [DB_PASSWORD_HERE] con contraseña de RDS
#   [ADMIN_PASSWORD_HERE] con contraseña de admin
#   [YOUR_GMAIL_HERE] con tu email de Gmail
#   [GMAIL_APP_PASSWORD_HERE] con app password de Gmail

# Registrar task definition
aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --region us-east-1
```

- [ ] Task definition registrada
- [ ] Verificar en ECS Console

## ✓ Fase 8: Crear Application Load Balancer (5 minutos)

```powershell
# Crear Security Group
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text

$ALB_SG = aws ec2 create-security-group --group-name eafit-alb-sg --description "ALB Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text

# Permitir HTTP y HTTPS
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0 --region us-east-1
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 443 --cidr 0.0.0.0/0 --region us-east-1

# Crear ALB
$SUBNETS = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0:2].SubnetId' --output text

aws elbv2 create-load-balancer --name eafit-alb --subnets $SUBNETS.Split() --security-groups $ALB_SG --scheme internet-facing --type application --region us-east-1

# Crear Target Group
aws elbv2 create-target-group --name eafit-tg-es --protocol HTTP --port 5000 --vpc-id $VPC_ID --target-type ip --region us-east-1
```

- [ ] Security Group creado
- [ ] ALB creado
- [ ] Target Group creado
- [ ] Obtener DNS del ALB

```powershell
aws elbv2 describe-load-balancers --names eafit-alb --region us-east-1 --query 'LoadBalancers[0].DNSName' --output text
```

## ✓ Fase 9: Registrar Dominio en Route 53 (5 minutos)

- [ ] Registrar o transferir dominio en Route 53
- [ ] Crear Hosted Zone
- [ ] Obtener nameservers

```powershell
aws route53 list-resource-record-sets --hosted-zone-id [HOSTED_ZONE_ID] --region us-east-1
```

- [ ] Crear registro A apuntando a ALB

```powershell
aws route53 change-resource-record-sets --hosted-zone-id [HOSTED_ZONE_ID] --change-batch '{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "tudominio.com",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z35SXDOTRQ7X7K",
        "DNSName": "[ALB_DNS]",
        "EvaluateTargetHealth": false
      }
    }
  }]
}'
```

## ✓ Fase 10: Configurar SSL/TLS con ACM (10 minutos)

- [ ] Solicitar certificado en ACM

```powershell
aws acm request-certificate --domain-name tudominio.com --subject-alternative-names "*.tudominio.com" --validation-method DNS --region us-east-1
```

- [ ] Validar dominio en Route 53
- [ ] Esperar validación (puede tomar minutos)
- [ ] Obtener Certificate ARN

```powershell
aws acm list-certificates --region us-east-1 --query 'CertificateSummaryList[0].CertificateArn' --output text
```

- [ ] Crear listener HTTPS en ALB

```powershell
aws elbv2 create-listener --load-balancer-arn [ALB_ARN] --protocol HTTPS --port 443 --certificates CertificateArn=[CERT_ARN] --default-actions Type=forward,TargetGroupArn=[TG_ARN] --region us-east-1
```

## ✓ Fase 11: Crear Servicios ECS (5 minutos)

```powershell
$CLUSTER = "eafit-cluster"
$TASK_DEF = "eafit-app"
$SERVICE_NAME = "eafit-service"
$DESIRED_COUNT = 1

# Obtener subnet y security group
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text
$SUBNETS = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0:2].SubnetId' --output text
$SG = aws ec2 describe-security-groups --filters "Name=group-name,Values=eafit-alb-sg" --query 'SecurityGroups[0].GroupId' --output text
$TG_ARN = aws elbv2 describe-target-groups --names eafit-tg-es --region us-east-1 --query 'TargetGroups[0].TargetGroupArn' --output text

# Crear servicio
aws ecs create-service `
  --cluster $CLUSTER `
  --service-name $SERVICE_NAME `
  --task-definition $TASK_DEF `
  --desired-count $DESIRED_COUNT `
  --launch-type FARGATE `
  --network-configuration "awsvpcConfiguration={subnets=[$($SUBNETS.Replace(' ',','))],securityGroups=[$SG]}" `
  --load-balancers "targetGroupArn=$TG_ARN,containerName=web-es,containerPort=5000" `
  --region us-east-1
```

- [ ] Servicio ECS creado
- [ ] Tareas ejecutándose

```powershell
aws ecs describe-services --cluster eafit-cluster --services eafit-service --region us-east-1
```

## ✓ Fase 12: Pruebas y Verificación (5 minutos)

- [ ] Acceder a http://[ALB_DNS]/es
- [ ] Acceder a https://tudominio.com/es (después de SSL)
- [ ] Formulario de registro funcionando
- [ ] Estadísticas cargando
- [ ] Email enviándose correctamente

```powershell
# Verificar logs
aws logs tail /ecs/eafit-web-es --follow --region us-east-1

# Verificar salud del servicio
aws ecs describe-services --cluster eafit-cluster --services eafit-service --region us-east-1 --query 'services[0].deployments'
```

## ✓ Fase 13: Monitoreo y Alertas (Opcional)

- [ ] Crear alertas en CloudWatch
- [ ] Configurar auto-scaling
- [ ] Crear snapshots de base de datos
- [ ] Configurar backup de RDS

## ✓ Fase 14: Documentación Final

- [ ] Documentar endpoints
- [ ] Guardar credenciales en lugar seguro
- [ ] Crear runbook de operaciones
- [ ] Documentar procedimiento de rollback

---

## Comandos Útiles de Verificación

```powershell
# Ver todos los recursos
aws ec2 describe-instances --region us-east-1
aws rds describe-db-instances --region us-east-1
aws ecs list-services --cluster eafit-cluster --region us-east-1
aws elbv2 describe-load-balancers --region us-east-1
aws ecr describe-repositories --region us-east-1

# Ver costos
aws ce get-cost-and-usage --time-period Start=2026-05-01,End=2026-05-31 --granularity MONTHLY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE

# Obtener información de recursos
$ALB_ARN = aws elbv2 describe-load-balancers --names eafit-alb --region us-east-1 --query 'LoadBalancers[0].LoadBalancerArn' --output text
$RDS_ENDPOINT = aws rds describe-db-instances --db-instance-identifier eafit-mysql-db --region us-east-1 --query 'DBInstances[0].Endpoint.Address' --output text
$ALB_DNS = aws elbv2 describe-load-balancers --names eafit-alb --region us-east-1 --query 'LoadBalancers[0].DNSName' --output text
```

---

## Duración Total Estimada
**~60-90 minutos** (dependiendo de validaciones de dominio y certificados)

## Costos Estimados
**~$40/mes** (Gratis con AWS Educate - $100 USD/mes de crédito)

---

**Última actualización**: Mayo 24, 2026  
**Estado**: Checklist Completo ✓
