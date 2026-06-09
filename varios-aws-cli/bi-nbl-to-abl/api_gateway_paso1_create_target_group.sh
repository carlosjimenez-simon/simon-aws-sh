#!/bin/bash

# --- CONFIGURACIÓN ---
# Nota: Recuerda cambiar el nombre para el de Keycloak cuando lo vayas a montar (ej: sm-dev-bi-keycloak-alb-tg)
TG_NAME="sm-dev-bi-api-gateway-alb-tg" 
VPC_ID="vpc-04c3946b71fc75d88"
PORT=9090 # El puerto en el que escucha tu API Gateway en el ALB
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "------------------------------------------------"
echo "🎯 Paso 1: Creando Target Group (NLB -> ALB)"
echo "------------------------------------------------"

# 1. Crear el Target Group tipo ALB
# Cambios clave: --target-type alb  y  --protocol TCP_UDP
TG_ARN=$(aws elbv2 create-target-group \
    --name "$TG_NAME" \
    --protocol TCP \
    --port $PORT \
    --vpc-id $VPC_ID \
    --target-type alb \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'TargetGroups[0].TargetGroupArn' --output text)

if [ $? -eq 0 ] && [ "$TG_ARN" != "None" ]; then
    echo "✅ Target Group tipo ALB creado: $TG_ARN"
else
    echo "❌ Error al crear el Target Group."
    exit 1
fi

echo "⚙️  Configurando atributos críticos (Cross-Zone)..."

# 2. Modificar atributos:
# - Solo dejamos cross_zone ya que preserve_client_ip no aplica para tipo 'alb'
aws elbv2 modify-target-group-attributes \
    --target-group-arn "$TG_ARN" \
    --attributes \
        Key=load_balancing.cross_zone.enabled,Value=true \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

if [ $? -eq 0 ]; then
    echo "✅ Atributos configurados correctamente."
else
    echo "⚠️  Error al configurar atributos."
fi

echo "------------------------------------------------"
echo "🚀 ¡TARGET GROUP LISTO PARA REGISTRAR EL ALB!"
echo "ARN: $TG_ARN"
echo "------------------------------------------------"