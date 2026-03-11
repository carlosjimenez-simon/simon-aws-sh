#!/bin/bash

# --- CONFIGURACIÓN ---
NAME="sm-dev-refactor-public-gps-lb"
TG_NAME="sm-dev-refactor-traccar-gps-tg"
PORT=5001 
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🔍 Buscando info del Target Group: $TG_NAME..."
TG_INFO=$(aws elbv2 describe-target-groups \
    --names $TG_NAME \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'TargetGroups[0].[TargetGroupArn,VpcId]' --output text 2>/dev/null)

TG_ARN=$(echo $TG_INFO | awk '{print $1}')
VPC_ID=$(echo $TG_INFO | awk '{print $2}')

if [ -z "$TG_ARN" ] || [ "$TG_ARN" == "None" ]; then
    echo "❌ Error: No se encontró el Target Group."
    exit 1
fi

echo "✅ TG encontrado en la VPC: $VPC_ID"

echo "🌐 Buscando subnets públicas únicas por zona en la VPC $VPC_ID..."

# Esta es la parte mágica: busca subnets con IGW, pero filtra para que solo salga UNA por Availability Zone
SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query "Subnets[?MapPublicIpOnLaunch==\`true\`]" \
    --output json | jq -r '[.[] | {SubnetId, AvailabilityZone}] | unique_by(.AvailabilityZone) | .[].SubnetId' | xargs)

# Si el comando de arriba no te funciona (por falta de jq), usa esta versión simplificada que toma las primeras 2 de la lista previa:
if [ -z "$SUBNETS" ]; then
    SUBNETS=$(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --region $AWS_REGION \
        --profile $AWS_PROFILE \
        --query "RouteTables[?Routes[?GatewayId != null && starts_with(GatewayId, 'igw-')]].Associations[0].SubnetId" \
        --output text | head -n 1) # Tomamos solo una para ir a la fija
fi

if [ -z "$SUBNETS" ] || [ "$SUBNETS" == "None" ]; then
    echo "❌ Error: No encontré subnets públicas."
    exit 1
fi

echo "✅ Usando subnet(s): $SUBNETS"

echo "🚀 Creando el Network Load Balancer Público..."
LB_ARN=$(aws elbv2 create-load-balancer \
    --name $NAME \
    --type network \
    --scheme internet-facing \
    --subnets $SUBNETS \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "⏳ Esperando 30 segundos..."
sleep 30

echo "🔗 Creando el Listener..."
aws elbv2 create-listener \
    --load-balancer-arn $LB_ARN \
    --protocol TCP \
    --port $PORT \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

echo "------------------------------------------------"
echo "✅ ¡LISTO, PARCE! Balanceador creado con éxito."
aws elbv2 describe-load-balancers --load-balancer-arns $LB_ARN --region $AWS_REGION --profile $AWS_PROFILE --query 'LoadBalancers[0].DNSName' --output text
echo "------------------------------------------------"