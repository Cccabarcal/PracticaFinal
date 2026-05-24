# Despliegue en AWS - Guía Paso a Paso

## 📋 Requisitos Previos

1. Cuenta AWS Educate activa
2. Dominio registrado (Freenom u otro)
3. Proyecto en GitHub
4. Terminal con acceso a git y SSH

---

## 🚀 Paso 1: Crear Instancia EC2

### 1.1 Acceder a AWS Console

1. Ir a https://aws.amazon.com/educate
2. Ingresar con cuenta universitaria
3. Abrir AWS Management Console

### 1.2 Crear Instancia

1. Ir a **EC2** → **Instancias** → **Lanzar instancia**

2. **Elegir AMI** (Amazon Machine Image):
   - Seleccionar **Ubuntu Server 22.04 LTS**
   - Verificar que sea **Elegible para capa gratuita**

3. **Tipo de instancia**:
   - Seleccionar **t2.micro** (gratuita)
   - Siguiente

4. **Detalles de instancia**:
   - Redes: VPC por defecto
   - Subred: Cualquiera
   - Siguiente

5. **Almacenamiento**:
   - Tamaño: 30 GB (gratuito)
   - Siguiente

6. **Etiquetas**:
   - Nombre: `eafit-practicafinal`
   - Siguiente

7. **Grupo de seguridad**:
   - Crear nuevo grupo: `eafit-sg`
   - Agregar reglas:
     - SSH (22) desde tu IP
     - HTTP (80) desde 0.0.0.0/0
     - HTTPS (443) desde 0.0.0.0/0
   - Revisar y lanzar

8. **Key Pair**:
   - Crear nueva: `eafit-key`
   - Descargar archivo `eafit-key.pem`
   - ⚠️ **Guardar en lugar seguro**

9. Hacer clic en **Lanzar instancias**

---

## 📡 Paso 2: Conectar a la Instancia

### 2.1 En Linux/Mac

```bash
# Cambiar permisos del archivo de clave
chmod 400 eafit-key.pem

# Conectar a la instancia
ssh -i eafit-key.pem ubuntu@<IP_ELASTICA>
```

### 2.2 En Windows

Usar PuTTY:
1. Descargar PuTTY desde https://putty.org/
2. Convertir PEM a PPK con PuTTYgen
3. Conectar con usuario `ubuntu`

---

## 🔧 Paso 3: Configurar Servidor

### 3.1 Actualizar Sistema

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl git wget
```

### 3.2 Instalar Docker

```bash
# Descargar script oficial
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario actual al grupo docker
sudo usermod -aG docker $USER

# Aplicar cambios
newgrp docker
```

### 3.3 Instalar Docker Compose

```bash
# Descargar última versión
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose

# Hacer ejecutable
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalación
docker-compose --version
```

### 3.4 Instalar OpenSSL (para certificados)

```bash
sudo apt-get install -y openssl
```

---

## 📁 Paso 4: Clonar Proyecto

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/PracticaFinal.git
cd PracticaFinal

# Verificar estructura
ls -la
```

---

## 🔐 Paso 5: Configurar Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar con tus valores
nano .env
```

Valores a cambiar:

```env
DB_PASSWORD=tu_contraseña_muy_segura_123
ADMIN_PASSWORD=tu_contraseña_admin_456
SMTP_USER=tu_email@gmail.com
SMTP_PASSWORD=contraseña_app_google
```

---

## 🔒 Paso 6: Generar Certificados SSL

### 6.1 Certificado Autofirmado (Temporal)

```bash
# Generar certificado válido por 1 año
bash generate_certs.sh
```

### 6.2 Certificado Let's Encrypt (Permanente)

```bash
# Instalar Certbot
sudo apt-get install -y certbot

# Obtener certificado (reemplaza con tu dominio)
sudo certbot certonly --standalone \
  -d tudominio.tk \
  -d www.tudominio.tk

# Copiar certificados
sudo cp /etc/letsencrypt/live/tudominio.tk/fullchain.pem certs/server.crt
sudo cp /etc/letsencrypt/live/tudominio.tk/privkey.pem certs/server.key

# Cambiar permisos
sudo chown $USER:$USER certs/*
```

---

## 🚀 Paso 7: Iniciar Servicios

```bash
# Construir imágenes
docker-compose build

# Iniciar en segundo plano
docker-compose up -d

# Verificar estado
docker-compose ps

# Ver logs
docker-compose logs -f
```

---

## 🌐 Paso 8: Configurar Dominio

### 8.1 Registrar Dominio Gratuito

1. Ir a https://www.freenom.com/
2. Buscar dominio (ej: `miproyecto.tk`)
3. Registrar por 3 meses
4. Anotar los nameservers de Freenom

### 8.2 Obtener IP Elástica en AWS

```bash
# En AWS Console:
# 1. Ir a EC2 → IP Elásticas
# 2. Asignar nueva IP
# 3. Asociar a tu instancia
```

### 8.3 Configurar DNS en Freenom

1. Ir a Freenom → Mis dominios
2. Seleccionar dominio
3. Management Tools → Nameservers
4. Usar nameservers de Freenom o personalizar:

```
A Record: @   → IP_ELASTICA (ej: 52.12.34.56)
A Record: www → IP_ELASTICA
```

⏳ **Esperar 24-48 horas para propagación DNS**

---

## ✅ Paso 9: Verificar Funcionamiento

```bash
# Probar desde local
curl -k https://localhost/es
curl -k https://localhost/en
curl -k https://localhost/stats

# Probar con dominio (después de DNS propagado)
curl -k https://tudominio.tk/es
curl -k https://www.tudominio.tk/en
```

---

## 📧 Paso 10: Configurar SMTP para Correos

### Usando Gmail

1. Activar "Contraseñas de aplicación":
   - Ir a myaccount.google.com
   - Seguridad → Contraseñas de aplicación
   - Crear contraseña para "Correo"

2. Actualizar `.env`:
   ```env
   SMTP_USER=tu_email@gmail.com
   SMTP_PASSWORD=contraseña_generada
   ```

3. Reiniciar servicio:
   ```bash
   docker-compose restart stats
   ```

---

## 📊 Paso 11: Mantener Servicios Activos

### Auto-reinicio en caso de falla

```bash
# Editar docker-compose.yml y cambiar:
restart_policy:
  condition: on-failure
  max_retries: 3
```

### Renovar certificados Let's Encrypt automáticamente

```bash
# Crear tarea cron
sudo crontab -e

# Agregar:
0 3 * * * certbot renew --quiet && docker-compose -f /home/ubuntu/PracticaFinal/docker-compose.yml restart nginx
```

---

## 🛡️ Paso 12: Seguridad Adicional

### Firewall

```bash
# Habilitar UFW
sudo ufw enable

# Permitir SSH (importante!)
sudo ufw allow 22/tcp

# Permitir HTTP y HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Verificar reglas
sudo ufw status
```

### Actualizar Sistema Regularmente

```bash
# Programar actualizaciones automáticas
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 🔍 Monitoreo

### Ver logs en tiempo real

```bash
# Todos los servicios
docker-compose logs -f

# Servicio específico
docker-compose logs -f nginx
docker-compose logs -f web-es
docker-compose logs -f db
```

### Verificar uso de recursos

```bash
docker stats
```

---

## 🆘 Solución de Problemas

### Servicios no inician

```bash
# Ver error completo
docker-compose up

# Reconstruir
docker-compose down
docker-compose up -d --build
```

### Error de permisos en certificados

```bash
# Cambiar permisos
sudo chown $USER:$USER certs/*
chmod 644 certs/server.crt
chmod 644 certs/server.key
```

### No me puedo conectar a HTTPS

```bash
# Verificar NGINX
docker-compose logs nginx

# Verificar certificados
openssl x509 -in certs/server.crt -text -noout

# Reiniciar
docker-compose restart nginx
```

---

## 📋 Checklist Final

- [ ] Instancia EC2 creada
- [ ] Grupo de seguridad configurado
- [ ] Key pair descargada
- [ ] Docker instalado
- [ ] Proyecto clonado
- [ ] Variables de entorno configuradas
- [ ] Certificados generados
- [ ] Servicios iniciados y funcionando
- [ ] Dominio registrado
- [ ] DNS configurado
- [ ] Acceso HTTPS funcionando
- [ ] Correos configurados
- [ ] Datos de respaldo
- [ ] Documentación en GitHub

---

## 💰 Costos Estimados

| Componente | Costo |
|-----------|-------|
| EC2 t2.micro | Gratis (1 año) |
| RDS mysql.t3.micro | ~$0.50/día |
| Transferencia de datos | Gratis (primeros 1 GB) |
| IP Elástica | Gratis |
| **Total estimado** | **~$15/mes** |

> Con créditos educate cubre varios años

---

## 📚 Referencias

- AWS Educate: https://aws.amazon.com/educate
- EC2 Pricing: https://aws.amazon.com/ec2/pricing/on-demand/
- Let's Encrypt: https://letsencrypt.org/
- Freenom: https://www.freenom.com/

---

¡Listo para producción! 🎉
