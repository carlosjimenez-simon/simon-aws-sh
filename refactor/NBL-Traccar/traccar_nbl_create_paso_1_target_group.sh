#!/bin/bash

# --- CONFIGURACIÓN ---
TG_NAME="sm-dev-refactor-traccar-gps-tg"
VPC_ID="vpc-04c3946b71fc75d88"
INSTANCE_ID="i-xxxxxxxxxxxxxx"     # Asegúrate de poner tu ID real aquí
PORT=5001
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🎯 Creando el Target Group tipo TCP..."
# Fíjate en los \ al final de cada línea, son vitales
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

echo "📍 Registrando la instancia $INSTANCE_ID en el Target Group..."
aws elbv2 register-targets \
    --target-group-arn $TG_ARN \
    --targets Id=$INSTANCE_ID \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

echo "------------------------------------------------"
echo "🚀 ¡TODO LISTO!"
echo "Copia este ARN y pégalo en tu script de 'subir' el Load Balancer:"
echo "$TG_ARN"
echo "------------------------------------------------"