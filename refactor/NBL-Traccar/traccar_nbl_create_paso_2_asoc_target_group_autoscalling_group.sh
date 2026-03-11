#!/bin/bash

# --- CONFIGURACIÓN ---
ASG_NAME="sm-dev-refactor-gps" # El nombre de tu Auto Scaling Group
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/sm-dev-refactor-traccar-gps-tg/f9f3781c1d513ed5"
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🔗 Asociando el Target Group con el Auto Scaling Group..."

aws autoscaling attach-load-balancer-target-groups \
    --auto-scaling-group-name $ASG_NAME \
    --target-group-arns $TG_ARN \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

if [ $? -eq 0 ]; then
    echo "✅ ¡Éxito! El ASG ahora registrará automáticamente sus instancias en este TG."
else
    echo "❌ Error al asociar el TG con el ASG."
    exit 1
fi