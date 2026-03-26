#!/bin/bash

# ARNs confirmados por ti hace un momento
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/tg-krakend-refactor/544fd7f824533fae"
LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:listener/app/sm-dev-refactor-apigw-lb/ed8213c18df49018/0866725291ede90e"
ORIGIN="https://d1liarl5t50641.cloudfront.net"

echo "🚀 Paso 1: Creando estructura de la regla..."
aws elbv2 create-rule \
    --listener-arn "$LISTENER_ARN" \
    --priority 10 \
    --conditions '[{"Field":"path-pattern","Values":["/*"]}]' \
    --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$TG_ARN\"}]" > /dev/null

echo "💉 Paso 2: Inyectando headers con sintaxis compatible..."
RULE_ARN=$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query "Rules[?Priority=='10'].RuleArn" --output text)

aws elbv2 modify-rule \
    --rule-arn "$RULE_ARN" \
    --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$TG_ARN\"}]" \
    --header-actions "{
        \"ResponseHeaderConfigurations\": [
            {
                \"HeaderKey\": \"Access-Control-Allow-Private-Network\",
                \"HeaderValue\": \"true\",
                \"Action\": \"OVERWRITE\"
            },
            {
                \"HeaderKey\": \"Access-Control-Allow-Origin\",
                \"HeaderValue\": \"$ORIGIN\",
                \"Action\": \"OVERWRITE\"
            },
            {
                \"HeaderKey\": \"Access-Control-Allow-Methods\",
                \"HeaderValue\": \"GET, POST, OPTIONS, PUT, DELETE\",
                \"Action\": \"OVERWRITE\"
            }
        ]
    }"

echo "✨ ¡Listo! Regla $RULE_ARN configurada."