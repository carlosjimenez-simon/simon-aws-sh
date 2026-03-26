#!/bin/bash

# --- Configuración ---
SECRET_NAME="dev/refactor/postgres"
REGION="us-east-1"
# Días que AWS guarda el secreto antes de borrarlo definitivamente (7 a 30)
RECOVERY_WINDOW=7 

# --- Ejecución ---
echo "🗑️  Programando borrado del secreto: $SECRET_NAME..."

aws secretsmanager delete-secret \
    --secret-id "$SECRET_NAME" \
    --recovery-window-in-days $RECOVERY_WINDOW \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo "✅ Secreto programado para borrado en $RECOVERY_WINDOW días."
else
    echo "❌ Error al intentar borrar el secreto."
fi