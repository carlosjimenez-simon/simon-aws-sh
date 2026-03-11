#!/bin/bash

# --- CONFIGURACIÓN ---
LB_NAME="sm-dev-refactor-public-gps-lb"
ASG_NAME="sm-dev-refactor-gps" # Pon el nombre de tu Auto Scaling Group
TG_NAME="sm-dev-refactor-traccar-gps-tg"
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "🔍 Buscando recursos..."

# 1. Obtener ARNs
LB_ARN=$(aws elbv2 describe-load-balancers --names $LB_NAME --profile $AWS_PROFILE --region $AWS_REGION --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
TG_ARN=$(aws elbv2 describe-target-groups --names $TG_NAME --profile $AWS_PROFILE --region $AWS_REGION --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)

# 2. Borrar el Load Balancer (esto borra el Listener automáticamente)
if [ ! -z "$LB_ARN" ] && [ "$LB_ARN" != "None" ]; then
    echo "🗑️ Borrando el Load Balancer (y sus listeners)..."
    aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN --profile $AWS_PROFILE --region $AWS_REGION
    echo "✅ Load Balancer eliminado."
else
    echo "ℹ️ El Load Balancer ya no existe."
fi

# 3. Desasociar el TG del Auto Scaling Group
if [ ! -z "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    echo "🔗 Desvinculando el Target Group del ASG..."
    aws autoscaling detach-load-balancer-target-groups \
        --auto-scaling-group-name $ASG_NAME \
        --target-group-arns $TG_ARN \
        --profile $AWS_PROFILE \
        --region $AWS_REGION
    
    echo "⏳ Esperando un momento para que se complete la desvinculación..."
    sleep 10

    # 4. Borrar el Target Group
    echo "🎯 Borrando el Target Group..."
    aws elbv2 delete-target-group --target-group-arn $TG_ARN --profile $AWS_PROFILE --region $AWS_REGION
    echo "✅ Target Group eliminado."
fi

echo "------------------------------------------------"
echo "🏁 ¡Limpieza completada, parce! No quedó nada volando."
echo "------------------------------------------------"