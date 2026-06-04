#!/bin/bash

# --- CONFIGURACIÓN ---
# Pegamos el ARN que te escupió el primer script
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/sm-dev-bi-superset-tg/4a6e3b03320621a1" 
INSTANCE_ID="i-0ff5278bde4c521c1"
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "------------------------------------------------"
echo "🔗 Asociando instancia fija al Target Group"
echo "------------------------------------------------"

# Registrar la instancia en el Target Group
aws elbv2 register-targets \
    --target-group-arn "$TG_ARN" \
    --targets Id="$INSTANCE_ID" \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

if [ $? -eq 0 ]; then
    echo "✅ Instancia $INSTANCE_ID asociada correctamente al Target Group."
else
    echo "❌ Error al asociar la instancia."
    exit 1
fi

echo "⏳ Esperando unos segundos para verificar el estado de salud (Health Check)..."
sleep 10

echo "------------------------------------------------"
echo "🔍 Estado actual del Target Group:"
echo "------------------------------------------------"

# Monitorear el estado de salud
aws elbv2 describe-target-health \
    --target-group-arn "$TG_ARN" \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'TargetHealthDescriptions[*].{InstanceID:Target.Id, Port:Target.Port, State:TargetHealth.State, Reason:TargetHealth.Reason}' \
    --output table