#!/bin/bash

# Variable del Listener (la misma que ya verificamos)
LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:listener/app/sm-dev-refactor-apigw-lb/ed8213c18df49018/43898b1c9ef811f9"

echo "🧹 Iniciando limpieza de reglas en el Listener 8082..."

# 1. Buscamos los ARNs de todas las reglas que NO son la default
RULES_TO_DELETE=$(aws elbv2 describe-rules \
    --listener-arn $LISTENER_ARN \
    --query "Rules[?IsDefault==\`false\`].RuleArn" \
    --output text)

# 2. Si hay reglas, las borramos una por una
if [ -z "$RULES_TO_DELETE" ] || [ "$RULES_TO_DELETE" == "None" ]; then
    echo "✅ No hay reglas adicionales para borrar. Solo queda la regla Default."
else
    for arn in $RULES_TO_DELETE; do
        echo "Borrando regla: $arn"
        aws elbv2 delete-rule --rule-arn $arn
    done
    echo "✅ ¡Limpieza completada! El puerto 8082 ahora está abierto según la regla Default."
fi
