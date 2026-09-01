#!/bin/bash

# --- Configuración ---
SECRET_NAME="dev/simon-refactor/finanzauto/municipalities"
REGION="us-east-1"
FILE_PATH="secret_for_client_generic.json" # El archivo que contiene los valores

# --- Ejecución ---
echo "🚀 Creando secreto: $SECRET_NAME..."

aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "Secreto para alcanzar camel y consumir los servicios de mundial de seguros" \
    --secret-string file://"$FILE_PATH" \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo "✅ Secreto creado con éxito."
else
    echo "❌ Hubo un error al crear el secreto."
fi