#!/bin/bash

LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:listener/app/sm-dev-refactor-apigw-lb/ed8213c18df49018/0866725291ede90e"

echo "🔍 Buscando regla con prioridad 10 para eliminar..."
RULE_ARN=$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query "Rules[?Priority=='10'].RuleArn" --output text)

if [ "$RULE_ARN" != "None" ] && [ -n "$RULE_ARN" ]; then
    echo "🗑️ Borrando regla: $RULE_ARN"
    aws elbv2 delete-rule --rule-arn "$RULE_ARN"
    echo "✅ Regla eliminada. El tráfico vuelve a la Default."
else
    echo "⚠️ No se encontró ninguna regla con prioridad 10."
fi