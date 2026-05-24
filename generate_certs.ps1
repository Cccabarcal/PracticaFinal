# Script para generar certificados SSL autofirmados en Windows
# Uso: .\generate_certs.ps1

# Crear directorio de certificados si no existe
if (!(Test-Path "certs")) {
    New-Item -ItemType Directory -Path "certs" | Out-Null
}

# Generar certificado autofirmado
$cert = New-SelfSignedCertificate `
    -CertStoreLocation "cert:\LocalMachine\My" `
    -DnsName "localhost", "web-en", "web-es", "nginx" `
    -FriendlyName "EAFIT Local Development" `
    -NotAfter (Get-Date).AddYears(1)

# Exportar certificado sin contraseña
$password = ConvertTo-SecureString -String "temp" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "certs/server.pfx" -Password $password

# Convertir PFX a PEM
$pfxPath = "certs/server.pfx"
$certPath = "certs/server.crt"
$keyPath = "certs/server.key"

# Usando OpenSSL (si está disponible)
if (Get-Command openssl -ErrorAction SilentlyContinue) {
    openssl pkcs12 -in $pfxPath -clcerts -nokeys -out $certPath -password pass:temp
    openssl pkcs12 -in $pfxPath -nocerts -nodes -out $keyPath -password pass:temp
    
    Write-Host "✅ Certificados SSL generados en certs/"
    Write-Host "   - certs/server.crt"
    Write-Host "   - certs/server.key"
} else {
    Write-Host "⚠️  OpenSSL no está instalado"
    Write-Host "   Certificado PFX disponible en: certs/server.pfx"
    Write-Host ""
    Write-Host "   Para convertir PFX a PEM, instala OpenSSL:"
    Write-Host "   https://slproweb.com/products/Win32OpenSSL.html"
}

Write-Host ""
Write-Host "⚠️  Los certificados son autofirmados y válidos por 365 días"
Write-Host "   Para producción, usa Let's Encrypt"
