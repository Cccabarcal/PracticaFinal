#!/bin/bash

# Script para generar certificados SSL autofirmados
# Uso: ./generate_certs.sh

# Crear directorio de certificados si no existe
mkdir -p certs

# Generar certificado privado y público autofirmados
openssl req -x509 \
    -newkey rsa:4096 \
    -nodes \
    -out certs/server.crt \
    -keyout certs/server.key \
    -days 365 \
    -subj "/C=CO/ST=Antioquia/L=Medellin/O=EAFIT/CN=localhost"

echo "✅ Certificados SSL generados en certs/"
echo "   - certs/server.crt"
echo "   - certs/server.key"
echo ""
echo "⚠️  Los certificados son autofirmados y válidos por 365 días"
echo "   Para producción, usa Let's Encrypt"
