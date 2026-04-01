#!/bin/bash

# --- CONFIGURACIÓN ---
TG_NAME="sm-dev-refactor-traccar-gps-teltonika-tg"
ASG_NAME="sm-dev-refactor-gps"
VPC_ID="vpc-04c3946b71fc75d88"
PORT=5001
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "------------------------------------------------"
echo "🎯 Paso 1: Creando Target Group para Traccar"
echo "------------------------------------------------"

# 1. Crear el Target Group
TG_ARN=$(aws elbv2 create-target-group \
    --name $TG_NAME \
    --protocol TCP \
    --port $PORT \
    --vpc-id $VPC_ID \
    --target-type instance \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'TargetGroups[0].TargetGroupArn' --output text)

if [ $? -eq 0 ] && [ "$TG_ARN" != "None" ]; then
    echo "✅ Target Group creado: $TG_ARN"
else
    echo "❌ Error al crear el Target Group."
    exit 1
fi

echo "⚙️  Configurando atributos críticos (Cross-Zone y Proxy Mode)..."

# 2. Modificar atributos: 
# - load_balancing.cross_zone.enabled=true (Para alcanzar cualquier AZ)
# - preserve_client_ip.enabled=false (Para asegurar compatibilidad de ruteo con el NLB)
aws elbv2 modify-target-group-attributes \
    --target-group-arn "$TG_ARN" \
    --attributes \
        Key=load_balancing.cross_zone.enabled,Value=true \
        Key=preserve_client_ip.enabled,Value=false \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

if [ $? -eq 0 ]; then
    echo "✅ Atributos configurados correctamente."
else
    echo "⚠️  Error al configurar atributos, revisa los permisos del perfil."
fi

echo "------------------------------------------------"
echo "🚀 ¡TARGET GROUP LISTO Y OPTIMIZADO!"
echo "Siguiente paso: ./traccar_nbl_create_paso_2_asoc_target_group_autoscalling_group.sh"
echo "ARN: $TG_ARN"
echo "------------------------------------------------"