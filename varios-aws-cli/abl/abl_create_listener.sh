#!/bin/bash

# --- CONFIGURACIÓN ---
LB_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:loadbalancer/net/sm-dev-refactor-message-queue-lb/826b381462e83bae"
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/sm-dev-refactor-msg-queue-adm-tg/ea3616719e9a0380"
PORT=15672
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🔗 Creando Listener TCP en puerto $PORT..."
aws elbv2 create-listener \
    --load-balancer-arn $LB_ARN \
    --protocol TCP --port $PORT \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --region $AWS_REGION --profile $AWS_PROFILE

echo "------------------------------------------------"
echo "✅ LISTENER CREADO!"
