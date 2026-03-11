#!/bin/bash

# --- CONFIGURACIÓN ---
ASG_NAME="sm-dev-refactor-gps" 
TG_NAME="sm-dev-refactor-traccar-gps-tg" # Ahora usamos el nombre
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🔍 Buscando el ARN del Target Group: $TG_NAME..."

# Buscamos el ARN automáticamente por el nombre
TG_ARN=$(aws elbv2 describe-target-groups \
    --names $TG_NAME \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)

if [ -z "$TG_ARN" ] || [ "$TG_ARN" == "None" ]; then
    echo "❌ Error: No se encontró un Target Group con el nombre '$TG_NAME'."
    exit 1
fi

echo "✅ ARN encontrado: $TG_ARN"
echo "🔗 Asociando el Target Group con el Auto Scaling Group ($ASG_NAME)..."

aws autoscaling attach-load-balancer-target-groups \
    --auto-scaling-group-name $ASG_NAME \
    --target-group-arns $TG_ARN \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

if [ $? -eq 0 ]; then
    echo "✅ ¡Éxito! El ASG ahora registrará automáticamente sus instancias en este TG."
else
    echo "❌ Error al asociar el TG con el ASG."
    exit 1
fi