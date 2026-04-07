#!/bin/bash

# --- CONFIGURACIÓN ---
LB_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:loadbalancer/app/sm-dev-refactor-alfresco-lb/9a5a632fd661670d"
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/sm-dev-refactor-alfresco-tg/36864c5b22cca707"
PORT=60000
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🔗 Creando Listener HTTP en puerto $PORT para ALB..."

# CAMBIO CLAVE: --protocol cambia de TCP a HTTP
aws elbv2 create-listener \
    --load-balancer-arn $LB_ARN \
    --protocol HTTP --port $PORT \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --region $AWS_REGION --profile $AWS_PROFILE

echo "------------------------------------------------"
echo "✅ LISTENER CREADO EN EL ALB!"