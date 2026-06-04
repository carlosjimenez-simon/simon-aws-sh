#!/bin/bash

# --- CONFIGURACIÓN ---
TG_NAME="sm-dev-bi-superset-tg"
VPC_ID="vpc-04c3946b71fc75d88"
PORT_INTERNO_SUPERSET=8082 
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "------------------------------------------------"
echo "🎯 Paso 1: Creando Target Group para Superset (ALB)"
echo "------------------------------------------------"

# 1. Crear el Target Group en HTTP para el ALB
TG_ARN=$(aws elbv2 create-target-group \
    --name "$TG_NAME" \
    --protocol HTTP \
    --port $PORT_INTERNO_SUPERSET \
    --vpc-id "$VPC_ID" \
    --target-type instance \
    --health-check-protocol HTTP \
    --health-check-path "/health" \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --query 'TargetGroups[0].TargetGroupArn' --output text)

if [ $? -eq 0 ] && [ "$TG_ARN" != "None" ]; then
    echo "✅ Target Group creado: $TG_ARN"
else
    echo "❌ Error al crear el Target Group."
    exit 1
fi

echo "⚙️ Configurando atributos críticos (Cross-Zone)..."

# 2. Modificar atributos válidos para ALB:
# En ALB, cross-zone se activa a nivel de Load Balancer por defecto, 
# pero es una buena práctica asegurar que el TG lo soporte.
aws elbv2 modify-target-group-attributes \
    --target-group-arn "$TG_ARN" \
    --attributes \
        Key=load_balancing.cross_zone.enabled,Value=true \
    --region $AWS_REGION \
    --profile $AWS_PROFILE

if [ $? -eq 0 ]; then
    echo "✅ Atributos configurados correctamente."
else
    echo "⚠️ Error al configurar atributos, revisa los permisos del perfil."
fi

echo "------------------------------------------------"
echo "🚀 ¡TARGET GROUP LISTO PARA ALB!"
echo "Siguiente paso: Asociar tus instancias/ASG a este TG y crear la regla en el ALB puerto 8082"
echo "ARN: $TG_ARN"
echo "-------------------------------------------------"