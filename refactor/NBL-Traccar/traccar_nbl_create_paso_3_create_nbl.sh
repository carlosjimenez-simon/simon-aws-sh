#!/bin/bash

# --- CONFIGURACIÓN ---
NAME="sm-dev-refactor-public-gps-lb"
TG_NAME="sm-dev-refactor-traccar-gps-tg"
TARGET_AZ="us-east-1b" 
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

echo "🌐 Buscando CUALQUIER subnet en $TARGET_AZ que pertenezca a la VPC..."
# Buscamos la primera subnet disponible en esa zona dentro de tu VPC
SUBNET_ID=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=availability-zone,Values=$TARGET_AZ" \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query "Subnets[0].SubnetId" --output text)

if [ "$SUBNET_ID" == "None" ] || [ -z "$SUBNET_ID" ]; then
    echo "❌ Error: No existe ninguna subnet en la zona $TARGET_AZ para esta VPC."
    exit 1
fi

echo "✅ Subnet encontrada: $SUBNET_ID"

echo "🚀 Creando el Network Load Balancer Público en $SUBNET_ID..."
LB_ARN=$(aws elbv2 create-load-balancer \
    --name $NAME \
    --type network \
    --scheme internet-facing \
    --subnets $SUBNET_ID \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "⚙️  Activando Cross-Zone..."
aws elbv2 modify-load-balancer-attributes \
    --load-balancer-arn $LB_ARN \
    --attributes Key=load_balancing.cross_zone.enabled,Value=true \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

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
echo "✅ ¡LISTO! DNS del Balanceador:"
aws elbv2 describe-load-balancers --load-balancer-arns $LB_ARN --region $AWS_REGION --profile $AWS_PROFILE --query 'LoadBalancers[0].DNSName' --output text
echo "------------------------------------------------"