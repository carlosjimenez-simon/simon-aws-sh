#!/bin/bash

# --- CONFIGURACIÓN ---
NAME="sm-dev-refactor-public-gps-lb"
# Usa los ID de las subnets que vimos en tu imagen
SUBNETS="subnet-046f41e5b130a36d5 subnet-0591561704cb05396" 
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/sm-dev-refactor-traccar-gps-tg/f9f3781c1d513ed5" # El que te dio el paso anterior
PORT=5001 # El puerto de tus GPS
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🚀 Creando el Network Load Balancer Público..."
LB_ARN=$(aws elbv2 create-load-balancer \
    --name $NAME \
    --type network \
    --scheme internet-facing \
    --subnets $SUBNETS \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)

if [ $? -ne 0 ]; then
    echo "❌ Error al crear el Load Balancer."
    exit 1
fi

echo "⏳ Esperando 10 segundos para que AWS procese el ARN..."
sleep 10

echo "🔗 Creando el Listener en el puerto $PORT..."
aws elbv2 create-listener \
    --load-balancer-arn $LB_ARN \
    --protocol TCP \
    --port $PORT \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

echo "------------------------------------------------"
echo "✅ ¡TODO MELO, PARCE!"
echo "Tu DNS pública para configurar los equipos es:"
aws elbv2 describe-load-balancers \
    --load-balancer-arns $LB_ARN \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'LoadBalancers[0].DNSName' --output text
echo "------------------------------------------------"