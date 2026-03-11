#!/bin/bash

# Variables confirmadas
LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:listener/app/sm-dev-refactor-apigw-lb/ed8213c18df49018/43898b1c9ef811f9"
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/tg-traccar-web-refactor/9f54b66114cfbc88"

echo "🛡️  Restaurando reglas de seguridad en el Listener 8082..."

# Prioridad 1: Excepciones para la Web
aws elbv2 create-rule \
    --listener-arn $LISTENER_ARN \
    --priority 1 \
    --conditions "Field=path-pattern,Values='/api/session','/api/session/*','/api/server'" \
    --actions "Type=forward,TargetGroupArn=$TG_ARN"

# Prioridad 2: Bloqueo de API Directa
aws elbv2 create-rule \
    --listener-arn $LISTENER_ARN \
    --priority 2 \
    --conditions "Field=path-pattern,Values='/api/*'" \
    --actions 'Type=fixed-response,FixedResponseConfig={MessageBody="Paila papa",StatusCode="403",ContentType="text/plain"}'

echo "✅ ¡Reglas aplicadas con éxito!"
