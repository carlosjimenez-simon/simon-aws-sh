#!/bin/bash

# --- CONFIGURACIÓN ---
NAME="sm-dev-refactor-public-gps-lb"
TG_NAME="sm-dev-refactor-traccar-gps-tg"

# --- SUBREDES CRÍTICAS ---
# 1a Pública (donde entra internet)
SUBNET_1A="subnet-0f22c994da543dda1" 
# 1b Privada (donde vive la instancia, necesaria para salud/NotInUse)
SUBNET_1B="subnet-097dbe4aef1543f3d" 

PORT=5001 
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "------------------------------------------------"
echo "🚀 Paso 3: Creando NLB Multi-Zona"
echo "------------------------------------------------"

echo "🔍 Buscando ARN del Target Group..."
TG_ARN=$(aws elbv2 describe-target-groups --names $TG_NAME --region $AWS_REGION --profile $AWS_PROFILE --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "🏗️  Creando NLB con presencia en Zona 1a y 1b..."
LB_ARN=$(aws elbv2 create-load-balancer \
    --name $NAME \
    --type network \
    --scheme internet-facing \
    --subnets $SUBNET_1A $SUBNET_1B \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)

if [ $? -eq 0 ]; then
    echo "✅ NLB Creado con éxito."
else
    echo "❌ Error al crear el NLB."
    exit 1
fi

echo "⚙️  Activando Cross-Zone Load Balancing en el NLB..."
aws elbv2 modify-load-balancer-attributes \
    --load-balancer-arn $LB_ARN \
    --attributes Key=load_balancing.cross_zone.enabled,Value=true \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

echo "⏳ Esperando 20 segundos para estabilización..."
sleep 20

echo "🔗 Creando Listener TCP en puerto $PORT..."
aws elbv2 create-listener \
    --load-balancer-arn $LB_ARN \
    --protocol TCP --port $PORT \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --region $AWS_REGION --profile $AWS_PROFILE

echo "------------------------------------------------"
echo "✅ ¡INFRAESTRUCTURA CREADA!"
DNS_NAME=$(aws elbv2 describe-load-balancers --load-balancer-arns $LB_ARN --region $AWS_REGION --profile $AWS_PROFILE --query 'LoadBalancers[0].DNSName' --output text)
echo "🔗 DNS: $DNS_NAME"
echo "Siguiente paso: ./traccar_nbl_create_paso_4_verify_nbl.sh"
echo "------------------------------------------------"