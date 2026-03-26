#!/bin/bash

# --- Configuración ---
SECRET_NAME="dev/refactor/postgres"
REGION="us-east-1"
FILE_PATH="secret-for-refactor.json" # Asegúrate de que este JSON tenga TODO lo que quieres que quede

# --- Ejecución ---
echo "🔄 Actualizando valores en el secreto: $SECRET_NAME..."

# Usamos put-secret-value para inyectar el nuevo contenido del archivo
aws secretsmanager put-secret-value \
    --secret-id "$SECRET_NAME" \
    --secret-string file://"$FILE_PATH" \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo "✅ Secreto actualizado con éxito (se creó una nueva versión)."
else
    echo "❌ Error al intentar actualizar el secreto. Verifica que el secreto exista y no esté programado para borrado."
fi