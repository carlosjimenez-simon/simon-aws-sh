#!/bin/bash

# 1. Pedir el ARN del Target Group
read -p "📌 Ingrese el ARN del Target Group: " TG_ARN

# Validar que no esté vacío
if [ -empty "$TG_ARN" ]; then
    echo "❌ Error: El ARN no puede estar vacío."
    exit 1
fi

AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

# 2. Pedir confirmación antes de proceder
echo "⚠️  ADVERTENCIA: Estás a punto de borrar el Target Group:"
echo "👉 $TG_ARN"
read -p "¿Estás seguro de que deseas continuar? (s/n): " CONFIRMATION

# 3. Evaluar la respuesta
if [[ "$CONFIRMATION" == "s" || "$CONFIRMATION" == "S" ]]; then
    echo "🎯 Borrando el Target Group..."
    aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --profile "$AWS_PROFILE" --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo "✅ Target Group eliminado con éxito."
    else
        echo "❌ Hubo un error al intentar eliminar el Target Group."
    fi
else
    echo "🚫 Operación cancelada por el usuario."
fi