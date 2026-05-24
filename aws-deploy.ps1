# Script de Despliegue en AWS
# Automatiza la mayoría del proceso de deployment

param(
    [string]$Action = "help",
    [string]$AwsRegion = "us-east-1",
    [string]$DbPassword = "EafitDB2025Secure!"
)

# Colores para output
$Green = @{ ForegroundColor = 'Green' }
$Red = @{ ForegroundColor = 'Red' }
$Yellow = @{ ForegroundColor = 'Yellow' }
$Blue = @{ ForegroundColor = 'Cyan' }

function Write-Step {
    param([string]$Message)
    Write-Host "
════════════════════════════════════════════════════════════" @Blue
    Write-Host "▶ $Message" @Blue
    Write-Host "════════════════════════════════════════════════════════════" @Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" @Green
}

function Write-Error-Message {
    param([string]$Message)
    Write-Host "✗ $Message" @Red
}

# ===== VERIFICAR AWS CLI =====
function Test-AwsCli {
    try {
        $version = aws --version
        Write-Success "AWS CLI encontrado: $version"
        return $true
    } catch {
        Write-Error-Message "AWS CLI no instalado. Instale desde: https://aws.amazon.com/cli/"
        return $false
    }
}

# ===== OBTENER ACCOUNT ID =====
function Get-AwsAccountId {
    $accountId = aws sts get-caller-identity --query 'Account' --output text
    Write-Success "Account ID: $accountId"
    return $accountId
}

# ===== CREAR ECR REPOSITORIES =====
function Create-EcrRepositories {
    Write-Step "Creando ECR Repositories"
    
    $repos = @("practicafinal-web-es", "practicafinal-web-en", "practicafinal-stats")
    
    foreach ($repo in $repos) {
        try {
            aws ecr create-repository `
                --repository-name $repo `
                --region $AwsRegion `
                --output text | Out-Null
            Write-Success "Repositorio creado: $repo"
        } catch {
            Write-Host "Repositorio $repo puede ya existir (ignore este mensaje)" @Yellow
        }
    }
}

# ===== PUSH DOCKER IMAGES A ECR =====
function Push-DockerImagesToEcr {
    param([string]$AccountId)
    
    Write-Step "Subiendo imágenes Docker a ECR"
    
    $EcrRegistry = "$AccountId.dkr.ecr.$AwsRegion.amazonaws.com"
    
    # Login en ECR
    Write-Host "Iniciando sesión en ECR..." @Yellow
    aws ecr get-login-password --region $AwsRegion | `
        docker login --username AWS --password-stdin $EcrRegistry
    
    Write-Success "Sesión iniciada en ECR"
    
    # Construir imágenes
    Write-Host "Construyendo imágenes Docker..." @Yellow
    docker-compose build
    
    # Etiquetar imágenes
    $images = @(
        @{local="practicafinal-web-es:latest"; remote="practicafinal-web-es:latest"},
        @{local="practicafinal-web-en:latest"; remote="practicafinal-web-en:latest"},
        @{local="practicafinal-stats:latest"; remote="practicafinal-stats:latest"}
    )
    
    foreach ($img in $images) {
        $fullImage = "$EcrRegistry/$($img.remote)"
        Write-Host "Etiquetando: $($img.local) → $fullImage" @Yellow
        docker tag $img.local $fullImage
        
        Write-Host "Subiendo: $fullImage" @Yellow
        docker push $fullImage
        Write-Success "Imagen subida: $($img.remote)"
    }
}

# ===== CREAR RDS MYSQL =====
function Create-RdsDatabase {
    Write-Step "Creando Base de Datos RDS MySQL"
    
    $VpcId = aws ec2 describe-vpcs `
        --filters "Name=isDefault,Values=true" `
        --query 'Vpcs[0].VpcId' `
        --output text
    
    Write-Host "VPC ID: $VpcId" @Yellow
    
    # Crear DB Subnet Group
    Write-Host "Creando DB Subnet Group..." @Yellow
    $subnets = aws ec2 describe-subnets `
        --filters "Name=vpc-id,Values=$VpcId" `
        --query 'Subnets[0:2].SubnetId' `
        --output text
    
    try {
        aws rds create-db-subnet-group `
            --db-subnet-group-name eafit-db-subnet `
            --db-subnet-group-description "Subnet group for EAFIT database" `
            --subnet-ids $subnets.Split() `
            --region $AwsRegion `
            --output text | Out-Null
        Write-Success "DB Subnet Group creado"
    } catch {
        Write-Host "DB Subnet Group puede ya existir" @Yellow
    }
    
    # Crear instancia RDS
    Write-Host "Creando instancia RDS MySQL (esto puede tomar 5-10 minutos)..." @Yellow
    
    aws rds create-db-instance `
        --db-instance-identifier eafit-mysql-db `
        --db-instance-class db.t3.micro `
        --engine mysql `
        --engine-version 8.0.35 `
        --master-username admin `
        --master-user-password $DbPassword `
        --allocated-storage 20 `
        --db-subnet-group-name eafit-db-subnet `
        --publicly-accessible true `
        --storage-type gp3 `
        --multi-az false `
        --backup-retention-period 7 `
        --region $AwsRegion `
        --output text | Out-Null
    
    Write-Success "Instancia RDS creada: eafit-mysql-db"
    Write-Host "IMPORTANTE: Guarde la contraseña: $DbPassword" @Red
}

# ===== CREAR ECS CLUSTER =====
function Create-EcsCluster {
    Write-Step "Creando ECS Cluster"
    
    aws ecs create-cluster `
        --cluster-name eafit-cluster `
        --region $AwsRegion `
        --output text | Out-Null
    
    Write-Success "ECS Cluster creado: eafit-cluster"
}

# ===== CREAR ALB =====
function Create-ApplicationLoadBalancer {
    Write-Step "Creando Application Load Balancer"
    
    $VpcId = aws ec2 describe-vpcs `
        --filters "Name=isDefault,Values=true" `
        --query 'Vpcs[0].VpcId' `
        --output text
    
    # Crear Security Group
    Write-Host "Creando Security Group..." @Yellow
    $SgId = aws ec2 create-security-group `
        --group-name eafit-alb-sg `
        --description "Security group for EAFIT ALB" `
        --vpc-id $VpcId `
        --query 'GroupId' `
        --output text
    
    Write-Success "Security Group creado: $SgId"
    
    # Permitir HTTP
    aws ec2 authorize-security-group-ingress `
        --group-id $SgId `
        --protocol tcp `
        --port 80 `
        --cidr 0.0.0.0/0 `
        --region $AwsRegion | Out-Null
    
    # Permitir HTTPS
    aws ec2 authorize-security-group-ingress `
        --group-id $SgId `
        --protocol tcp `
        --port 443 `
        --cidr 0.0.0.0/0 `
        --region $AwsRegion | Out-Null
    
    Write-Success "Reglas de Security Group configuradas"
    
    # Crear ALB
    Write-Host "Creando ALB..." @Yellow
    $subnets = aws ec2 describe-subnets `
        --filters "Name=vpc-id,Values=$VpcId" `
        --query 'Subnets[0:2].SubnetId' `
        --output text
    
    aws elbv2 create-load-balancer `
        --name eafit-alb `
        --subnets $subnets.Split() `
        --security-groups $SgId `
        --scheme internet-facing `
        --type application `
        --region $AwsRegion `
        --output text | Out-Null
    
    Write-Success "Application Load Balancer creado: eafit-alb"
}

# ===== SETUP COMPLETO =====
function Setup-All {
    Write-Host "
    ╔════════════════════════════════════════════════════════╗
    ║   Despliegue Completo a AWS - EAFIT PracticaFinal     ║
    ║                                                        ║
    ║   Este script configurará:                            ║
    ║   • ECR Repositories                                  ║
    ║   • Imágenes Docker                                   ║
    ║   • RDS MySQL Database                                ║
    ║   • ECS Cluster                                       ║
    ║   • Application Load Balancer                         ║
    ║                                                        ║
    ║   Tiempo estimado: 15-20 minutos                      ║
    ╚════════════════════════════════════════════════════════╝
    " @Blue
    
    if (-not (Test-AwsCli)) { exit 1 }
    
    $accountId = Get-AwsAccountId
    
    # Crear ECR
    Create-EcrRepositories
    
    # Push Docker images
    Push-DockerImagesToEcr -AccountId $accountId
    
    # Crear RDS
    Create-RdsDatabase
    
    # Crear ECS
    Create-EcsCluster
    
    # Crear ALB
    Create-ApplicationLoadBalancer
    
    Write-Host "
    ╔════════════════════════════════════════════════════════╗
    ║              ✓ SETUP COMPLETADO                       ║
    ║                                                        ║
    ║   Próximos pasos:                                      ║
    ║   1. Registrar dominio en Route 53                    ║
    ║   2. Solicitar certificado SSL en ACM                 ║
    ║   3. Crear ECS Services                               ║
    ║   4. Configurar registros DNS                         ║
    ║                                                        ║
    ║   Ver AWS_DEPLOYMENT_GUIDE.md para detalles           ║
    ╚════════════════════════════════════════════════════════╝
    " @Green
}

# ===== STATUS CHECK =====
function Show-Status {
    Write-Step "Estado de Recursos AWS"
    
    Write-Host "`n📦 ECR Repositories:" @Blue
    aws ecr describe-repositories --region $AwsRegion --query 'repositories[*].[repositoryName,repositoryUri]' --output table
    
    Write-Host "`n🗄️  RDS Instances:" @Blue
    aws rds describe-db-instances --region $AwsRegion --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine]' --output table
    
    Write-Host "`n🎯 ECS Clusters:" @Blue
    aws ecs list-clusters --region $AwsRegion --query 'clusterArns' --output table
    
    Write-Host "`n⚖️  Load Balancers:" @Blue
    aws elbv2 describe-load-balancers --region $AwsRegion --query 'LoadBalancers[*].[LoadBalancerName,DNSName,State.Code]' --output table
}

# ===== HELP =====
function Show-Help {
    Write-Host "
    ╔════════════════════════════════════════════════════════╗
    ║           Script de Despliegue AWS - EAFIT            ║
    ║                                                        ║
    ║   Uso: .\aws-deploy.ps1 -Action <action>              ║
    ║                                                        ║
    ║   Acciones disponibles:                               ║
    ║                                                        ║
    ║   setup-all      : Setup completo (ECR, RDS, ECS)     ║
    ║   create-ecr     : Crear ECR repositories             ║
    ║   push-images    : Subir imágenes Docker a ECR        ║
    ║   create-rds     : Crear base de datos RDS            ║
    ║   create-ecs     : Crear ECS cluster                  ║
    ║   create-alb     : Crear Application Load Balancer    ║
    ║   status         : Ver estado de recursos             ║
    ║   help           : Mostrar esta ayuda                 ║
    ║                                                        ║
    ║   Opciones:                                           ║
    ║   -AwsRegion     : Región AWS (default: us-east-1)    ║
    ║   -DbPassword    : Contraseña RDS (default: generada) ║
    ║                                                        ║
    ║   Ejemplos:                                           ║
    ║   .\aws-deploy.ps1 -Action setup-all                  ║
    ║   .\aws-deploy.ps1 -Action status                     ║
    ║   .\aws-deploy.ps1 -Action create-rds -DbPassword xyz ║
    ║                                                        ║
    ╚════════════════════════════════════════════════════════╝
    "
}

# ===== MAIN =====
switch ($Action.ToLower()) {
    "setup-all"    { Setup-All }
    "create-ecr"   { Create-EcrRepositories }
    "push-images"  { Push-DockerImagesToEcr -AccountId (Get-AwsAccountId) }
    "create-rds"   { Create-RdsDatabase }
    "create-ecs"   { Create-EcsCluster }
    "create-alb"   { Create-ApplicationLoadBalancer }
    "status"       { Show-Status }
    "help"         { Show-Help }
    default        { Show-Help }
}
