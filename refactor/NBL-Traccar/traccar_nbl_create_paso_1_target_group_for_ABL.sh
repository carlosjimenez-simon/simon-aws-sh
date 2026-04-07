#!/bin/bash

# --- CONFIGURACIÓN ---
TG_NAME="sm-dev-refactor-alfresco-tg"
VPC_ID="vpc-04c3946b71fc75d88"
PORT=60000
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

echo "------------------------------------------------"
echo "🎯 Paso 1: Creando Target Group HTTP para ALB"
echo "------------------------------------------------"

# 1. Crear el Target Group y capturar el ARN
# Cambiamos protocolo a HTTP porque el ALB no acepta Target Groups TCP
TG_ARN=$(aws elbv2 create-target-group \
    --name "$TG_NAME" \
    --protocol HTTP \
    --port "$PORT" \
    --vpc-id "$VPC_ID" \
    --target-type instance \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

# Validar si el ARN se obtuvo correctamente
if [ -z "$TG_ARN" ] || [ "$TG_ARN" == "None" ]; then
    echo "❌ Error: No se pudo crear el Target Group."
    echo "Revisa si ya existe uno con el mismo nombre pero diferente protocolo (TCP)."
    exit 1
fi

echo "✅ Target Group creado: $TG_ARN"

echo "⚙️ Configurando atributos (Cross-Zone enabled)..."

# 2. Modificar atributos:
# - cross_zone.enabled=true (Para que el ALB balancee bien entre todas las AZ)
# Nota: Quitamos 'preserve_client_ip' porque el ALB usa X-Forwarded-For automáticamente
aws elbv2 modify-target-group-attributes \
    --target-group-arn "$TG_ARN" \
    --attributes Key=load_balancing.cross_zone.enabled,Value=true \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"

if [ $? -eq 0 ]; then
    echo "✅ Atributos configurados correctamente."
else
    echo "⚠️ Error al configurar atributos, revisa los permisos."
fi

echo "------------------------------------------------"
echo "🚀 ¡TARGET GROUP LISTO PARA USAR EN EL ALB!"
echo "ARN: $TG_ARN"
echo "------------------------------------------------"