#!/bin/bash

# --- CONFIGURACIÓN ---
LB_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:loadbalancer/net/sm-dev-refactor-public-gps-lb/d8c57598fdc399c8"
PORT=5027
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/sm-dev-refactor-traccar-gps-tg/968b88153c5e964a"
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🔍 Verificando si el listener en el puerto $PORT ya existe..."
EXISTING_LISTENER=$(aws elbv2 describe-listeners --load-balancer-arn "$LB_ARN" --region "$AWS_REGION" --profile "$AWS_PROFILE" --query "Listeners[?Port==\`$PORT\`].ListenerArn" --output text)

if [ -z "$EXISTING_LISTENER" ]; then
    echo "🔗 Creando Listener TCP en puerto $PORT..."
    aws elbv2 create-listener \
        --load-balancer-arn "$LB_ARN" \
        --protocol TCP \
        --port "$PORT" \
        --default-actions Type=forward,TargetGroupArn="$TG_ARN" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
else
    echo "⚠️  El listener en el puerto $PORT ya existe. Saltando creación."
fi

echo "------------------------------------------------"
echo "✅ ¡PROCESO FINALIZADO!"
DNS_NAME=$(aws elbv2 describe-load-balancers --load-balancer-arns "$LB_ARN" --region "$AWS_REGION" --profile "$AWS_PROFILE" --query 'LoadBalancers[0].DNSName' --output text)
echo "🔗 DNS: $DNS_NAME"
echo "Siguiente paso: ./traccar_nbl_create_paso_4_verify_nbl.sh"
echo "------------------------------------------------"