#!/bin/bash

# --- CONFIGURACIÓN ---
LB_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:loadbalancer/app/sm-dev-refactor-apigw-lb/ed8213c18df49018"
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/sm-dev-bi-superset-tg/4a6e3b03320621a1"
# Sacamos el ARN del certificado que se ve en tu listener 9090
CERTIFICATE_ARN="arn:aws:acm:us-east-1:707925622299:certificate/12fa4a6c-b1e5-46cd-b90e-ba117142e768"
PORT=8082
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🔗 Creando Listener HTTPS en puerto $PORT para ALB..."

# Ajustamos protocolo a HTTPS y añadimos el certificado obligatorio
aws elbv2 create-listener \
    --load-balancer-arn "$LB_ARN" \
    --protocol HTTPS \
    --port $PORT \
    --certificates CertificateArn="$CERTIFICATE_ARN" \
    --default-actions Type=forward,TargetGroupArn="$TG_ARN" \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

if [ $? -eq 0 ]; then
    echo "------------------------------------------------"
    echo "✅ ¡LISTENER HTTPS:$PORT CREADO EXITOSAMENTE EN EL ALB!"
    echo "------------------------------------------------"
else
    echo "❌ Error al crear el listener. Revisa los ARNs o permisos."
    exit 1
fi