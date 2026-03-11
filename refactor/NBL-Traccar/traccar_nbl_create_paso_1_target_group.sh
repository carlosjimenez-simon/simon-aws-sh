#!/bin/bash

# --- CONFIGURACIÓN ---
TG_NAME="sm-dev-refactor-traccar-gps-tg"
VPC_ID="vpc-04c3946b71fc75d88"
PORT=5001
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🎯 Creando el Target Group tipo TCP..."

TG_ARN=$(aws elbv2 create-target-group \
    --name $TG_NAME \
    --protocol TCP \
    --port $PORT \
    --vpc-id $VPC_ID \
    --target-type instance \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'TargetGroups[0].TargetGroupArn' --output text)

if [ $? -eq 0 ] && [ "$TG_ARN" != "None" ]; then
    echo "✅ Target Group creado: $TG_ARN"
else
    echo "❌ Error al crear el Target Group."
    exit 1
fi

echo "------------------------------------------------"
echo "🚀 ¡TARGET GROUP LISTO!"
echo "Ahora usa el Script 2 para asociarlo al ASG: $ASG_NAME"
echo "ARN: $TG_ARN"
echo "------------------------------------------------"