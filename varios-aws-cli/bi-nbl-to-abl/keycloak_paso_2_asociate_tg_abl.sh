#!/bin/bash

# --- CONFIGURACIÓN ---
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/sm-dev-bi-keycloak-alb-tg/5e836b1e95d2ec69"
ALB_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:loadbalancer/app/sm-dev-refactor-apigw-lb/ed8213c18df49018"
NLB_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:loadbalancer/net/sm-dev-refactor-public-gps-lb/d8c57598fdc399c8"

PORT=8080
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "------------------------------------------------"
echo "🔗 Paso 2: Registrando ALB interno en el Target Group"
echo "------------------------------------------------"

aws elbv2 register-targets \
    --target-group-arn "$TG_ARN" \
    --targets Id="$ALB_ARN" \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

if [ $? -eq 0 ]; then
    echo "✅ ALB registrado con éxito en el Target Group."
else
    echo "❌ Error al registrar el ALB en el Target Group."
    exit 1
fi

echo "------------------------------------------------"
echo "🎧 Paso 3: Creando Listener en el NLB Público (Puerto $PORT)"
echo "------------------------------------------------"

aws elbv2 create-listener \
    --load-balancer-arn "$NLB_ARN" \
    --protocol TCP \
    --port $PORT \
    --default-actions Type=forward,TargetGroupArn="$TG_ARN" \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

if [ $? -eq 0 ]; then
    echo "✅ Listener TCP:$PORT creado con éxito en el NLB."
else
    echo "❌ Error al crear el Listener en el NLB."
    exit 1
fi

echo "------------------------------------------------"
echo "🚀 ¡PUENTE COMPLETADO!"
echo "Revisa en la consola que el Target Group pase a 'Healthy' en unos minutos."
echo "------------------------------------------------"