# Configuración para AWS

Este archivo contiene la configuración necesaria para desplegar la aplicación en AWS.

## Archivos incluidos en este directorio

### 1. `AWS_DEPLOYMENT_GUIDE.md` 
**Guía completa paso a paso del despliegue en AWS**
- Configuración inicial
- Creación de ECR (Elastic Container Registry)
- Subida de imágenes Docker
- Configuración de RDS MySQL
- Creación de ECS Cluster
- Setup de Application Load Balancer
- Configuración de dominio en Route 53
- SSL/TLS con AWS Certificate Manager

### 2. `aws-deploy.ps1`
**Script PowerShell de automatización**
```powershell
# Ejecutar setup completo
.\aws-deploy.ps1 -Action setup-all

# Ver estado de recursos
.\aws-deploy.ps1 -Action status

# Acciones individuales
.\aws-deploy.ps1 -Action create-ecr
.\aws-deploy.ps1 -Action push-images
.\aws-deploy.ps1 -Action create-rds
.\aws-deploy.ps1 -Action create-ecs
.\aws-deploy.ps1 -Action create-alb
```

### 3. `.env.aws.example`
**Archivo de variables de entorno para AWS**
Copiar a `.env.aws` y completar con tus valores

---

## Pasos Rápidos

### Opción A: Setup Automatizado (Recomendado)

```powershell
# 1. Instalar AWS CLI
choco install awscli

# 2. Configurar credenciales
aws configure
# Ingresar: Access Key, Secret Key, Region (us-east-1), Output format (json)

# 3. Verificar configuración
aws sts get-caller-identity

# 4. Ejecutar script de deployment
cd "d:\Users\Cristian\Documents\Visual Projects\PracticaFinal"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\aws-deploy.ps1 -Action setup-all
```

### Opción B: Setup Manual

Seguir paso a paso la guía en `AWS_DEPLOYMENT_GUIDE.md`

---

## Costos Estimados (AWS Educate)

| Servicio | Costo/Mes | Acceso |
|----------|-----------|--------|
| ECR | $0.10 por GB almacenado | Gratis con Educate |
| ECS Fargate | $13-20 | Gratis con Educate |
| RDS MySQL | $9.50 | Gratis con Educate |
| ALB | $16.20 | Gratis con Educate |
| Route 53 | $0.50 | Gratis con Educate |
| **Total** | **~$40** | **Gratis con Educate** |

Con **AWS Educate** recibes **$100 USD/mes** de crédito, lo que cubre completamente estos costos.

---

## Verificación Post-Despliegue

```powershell
# 1. Verificar ECR
aws ecr describe-repositories --region us-east-1

# 2. Verificar RDS
aws rds describe-db-instances --db-instance-identifier eafit-mysql-db --region us-east-1

# 3. Verificar ECS
aws ecs list-clusters --region us-east-1

# 4. Verificar ALB
aws elbv2 describe-load-balancers --names eafit-alb --region us-east-1

# 5. Obtener DNS del ALB
aws elbv2 describe-load-balancers --names eafit-alb --region us-east-1 --query 'LoadBalancers[0].DNSName' --output text

# 6. Probar aplicación
# Abrir en navegador: http://[ALB_DNS]/es
```

---

## Configuración de Variables de Entorno en ECS

En el archivo `ecs-task-definition.json` se configuran:

```json
{
  "name": "DB_HOST",
  "value": "[RDS_ENDPOINT_AQUI]"
},
{
  "name": "DB_USER",
  "value": "admin"
},
{
  "name": "DB_PASSWORD",
  "value": "[CONTRASEÑA_RDS_AQUI]"
},
{
  "name": "DB_NAME",
  "value": "usuarios"
},
{
  "name": "ADMIN_PASSWORD",
  "value": "admin123"
},
{
  "name": "SMTP_SERVER",
  "value": "smtp.gmail.com"
},
{
  "name": "SMTP_PORT",
  "value": "587"
},
{
  "name": "SMTP_USER",
  "value": "[TU_EMAIL_GMAIL]"
},
{
  "name": "SMTP_PASSWORD",
  "value": "[TU_APP_PASSWORD_GMAIL]"
}
```

---

## Solución de Problemas

### Error: "Access Denied" en ECR
```powershell
# Verificar credenciales
aws sts get-caller-identity

# Renovar credenciales si es necesario
aws configure
```

### RDS tarda mucho en crearse
- Normal: puede tomar 5-10 minutos
- Verificar estado: `aws rds describe-db-instances --db-instance-identifier eafit-mysql-db --query 'DBInstances[0].DBInstanceStatus'`

### ALB no responde
```powershell
# Verificar que servicios ECS estén ejecutándose
aws ecs describe-services --cluster eafit-cluster --services eafit-service --region us-east-1

# Ver logs
aws logs get-log-events --log-group-name /ecs/eafit-web-es
```

### Problemas de SSL/TLS
1. Solicitar certificado en AWS Certificate Manager
2. Validar dominio en Route 53
3. Esperar validación (minutos)
4. Crear listener HTTPS en ALB

---

## Recursos Útiles

- **AWS Console**: https://console.aws.amazon.com/
- **AWS Educate**: https://aws.amazon.com/education/awseducate/
- **ECR Best Practices**: https://docs.aws.amazon.com/AmazonECR/latest/userguide/
- **ECS Best Practices**: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/
- **RDS Best Practices**: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/

---

## Después del Despliegue

### 1. Configurar Monitoreo
```powershell
# Crear alarmas en CloudWatch
# Ver métricas de recursos
aws cloudwatch list-metrics --region us-east-1
```

### 2. Configurar Auto-Scaling
```powershell
# Crear políticas de escalado automático en ECS
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/eafit-cluster/eafit-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 1 \
  --max-capacity 3 \
  --region us-east-1
```

### 3. Backup y Recovery
- RDS tiene backups automáticos (7 días de retención configurados)
- Configurar snapshots de RDS para backups a largo plazo

---

**Creado**: Mayo 24, 2026  
**Versión**: 1.0  
**Estado**: Producción
