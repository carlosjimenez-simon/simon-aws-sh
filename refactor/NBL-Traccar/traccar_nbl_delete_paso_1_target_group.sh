#!/bin/bash

# --- CONFIGURACIÓN ---
TG_NAME="sm-dev-refactor-traccar-gps-tg"
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🔍 Buscando el ARN del Target Group: $TG_NAME..."
TG_ARN=$(aws elbv2 describe-target-groups \
    --names $TG_NAME \
    --profile $AWS_PROFILE \
    --region $AWS_REGION \
    --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)

if [ -z "$TG_ARN" ] || [ "$TG_ARN" == "None" ]; then
    echo "❌ No se encontró el Target Group '$TG_NAME'. ¿Ya fue eliminado?"
    exit 1
fi

echo "🎯 Eliminando el Target Group..."
aws elbv2 delete-target-group \
    --target-group-arn $TG_ARN \
    --profile $AWS_PROFILE \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    echo "✅ ¡Listo! Target Group eliminado correctamente."
else
    echo "❌ Error al intentar eliminar el Target Group."
fi