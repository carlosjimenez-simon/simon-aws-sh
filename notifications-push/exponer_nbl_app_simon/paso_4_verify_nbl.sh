#!/bin/bash

# --- CONFIGURACIÓN ---
TG_NAME="sm-dev-notifications-tg"
LB_NAME="sm-dev-refactor-public-gps-lb"
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "------------------------------------------------"
echo "🏥 Monitor de Salud Automático: $TG_NAME"
echo "------------------------------------------------"

# 1. Buscar el ARN del Target Group
TG_ARN=$(aws elbv2 describe-target-groups \
    --names "$TG_NAME" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" \
    --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)

if [ -z "$TG_ARN" ] || [ "$TG_ARN" == "None" ]; then
    echo "❌ Error: No se encontró el Target Group '$TG_NAME'."
    exit 1
fi

# 2. Consultar salud de las instancias
echo "📊 Estado de las instancias:"
aws elbv2 describe-target-health \
    --target-group-arn "$TG_ARN" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'TargetHealthDescriptions[*].{ID:Target.Id, Puerto:Target.Port, Estado:TargetHealth.State, Motivo:TargetHealth.Reason}' \
    --output table

echo ""
echo "🌐 Información de Conexión Pública:"

# 3. Obtener el DNS del Load Balancer
LB_DNS=$(aws elbv2 describe-load-balancers \
    --names "$LB_NAME" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" \
    --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null)

if [ ! -z "$LB_DNS" ] && [ "$LB_DNS" != "None" ]; then
    echo "🔗 DNS: $LB_DNS"
    
    # 4. Resolver la IP Pública (Usando dig)
    LB_IP=$(dig +short "$LB_DNS" | tail -n1)
    
    if [ ! -z "$LB_IP" ]; then
        echo "📍 IP Pública: $LB_IP"
        echo ""
        echo "🚀 Prueba reina (copia y pega):"
        echo "nc -vz $LB_IP 9090"
    else
        echo "⏳ IP: El DNS se está propagando, intenta en un momento..."
    fi
else
    echo "⚠️  No se encontró el Load Balancer '$LB_NAME' aún."
fi

echo "------------------------------------------------"