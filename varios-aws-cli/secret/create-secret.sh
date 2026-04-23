#!/bin/bash

# --- Configuración ---
SECRET_NAME="dev/simon-pay/intermediator"
REGION="us-east-1"
FILE_PATH="secret_for_simon_pay.json" # El archivo que contiene los valores

# --- Ejecución ---
echo "🚀 Creando secreto: $SECRET_NAME..."

aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "Configuración de RabbitMQ para el refactor de API GW" \
    --secret-string file://"$FILE_PATH" \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo "✅ Secreto creado con éxito."
else
    echo "❌ Hubo un error al crear el secreto."
fi