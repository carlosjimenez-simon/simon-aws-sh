#!/bin/bash

# --- CONFIGURACIÓN ---
TG_NAME="sm-dev-notifications-tg"
ASG_NAME="sm-dev-refactor-apigw-asg"
LB_NAME="sm-dev-refactor-public-gps-lb"
PORT=9090
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "------------------------------------------------"
echo "🧹 Limpiando infraestructura: Puerto $PORT"
echo "------------------------------------------------"

# 1. Buscar ARN del Load Balancer
LB_ARN=$(aws elbv2 describe-load-balancers --names "$LB_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# 2. Buscar ARN del Listener (por puerto)
echo "🔍 Buscando Listener en el puerto $PORT..."
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$LB_ARN" --region "$AWS_REGION" --profile "$AWS_PROFILE" --query "Listeners[?Port==\`$PORT\`].ListenerArn" --output text)

if [ ! -z "$LISTENER_ARN" ] && [ "$LISTENER_ARN" != "None" ]; then
    echo "🗑️  Eliminando Listener: $LISTENER_ARN"
    aws elbv2 delete-listener --listener-arn "$LISTENER_ARN" --region "$AWS_REGION" --profile "$AWS_PROFILE"
    echo "✅ Listener eliminado."
else
    echo "⚠️  No se encontró Listener en el puerto $PORT."
fi

# 3. Desvincular el Target Group del Auto Scaling Group
echo "🔍 Buscando ARN del Target Group..."
TG_ARN=$(aws elbv2 describe-target-groups --names "$TG_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" --query 'TargetGroups[0].TargetGroupArn' --output text)

if [ ! -z "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    echo "🔗 Desvinculando TG del Auto Scaling Group $ASG_NAME..."
    aws autoscaling detach-load-balancer-target-groups \
        --auto-scaling-group-name "$ASG_NAME" \
        --target-group-arns "$TG_ARN" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    
    echo "⏳ Esperando a que el ASG libere el TG (15 seg)..."
    sleep 15

    # 4. Eliminar el Target Group
    echo "🗑️  Eliminando Target Group: $TG_NAME"
    aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region "$AWS_REGION" --profile "$AWS_PROFILE"
    echo "✅ Target Group eliminado."
else
    echo "⚠️  No se encontró el Target Group '$TG_NAME'."
fi

echo "------------------------------------------------"
echo "✨ ¡LIMPIEZA COMPLETADA!"
echo "------------------------------------------------"