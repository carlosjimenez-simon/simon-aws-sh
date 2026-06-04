#!/bin/bash

# 1. Definir nombres de variables
POLICY_NAME="sm-dev-secrets-read-policy"
ROLE_NAME="sm-dev-core-ec2-role"

echo "Creando el archivo de la política JSON..."

# 2. Crear el archivo JSON con la política (Permite GetSecretValue en todos los secretos)
cat <<EOF > secrets_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowReadAllSecrets",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": "*"
        }
    ]
}
EOF

echo "Creando la política en AWS..."

# 3. Crear la política en IAM y guardar el ARN resultante
POLICY_ARN=$(aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document file://secrets_policy.json \
    --query 'Policy.Arn' \
    --output text)

if [ $? -eq 0 ]; then
    echo "¡Política creada con éxito! ARN: $POLICY_ARN"
    
    echo "Asociando la política al rol $ROLE_NAME..."
    
    # 4. Adjuntar la política al rol de tu EC2
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "$POLICY_ARN"
    
    if [ $? -eq 0 ]; then
        echo "--------------------------------------------------------"
        echo "¡Todo listo, parce! El rol ahora puede leer los secretos."
        echo "Dale un par de segundos para que AWS propague el cambio y reintenta."
        echo "--------------------------------------------------------"
    else
        echo "Error al adjuntar la política al rol. Revisa si el nombre del rol es correcto."
    fi
else
    echo "Hubo un error al crear la política. Revisa los permisos de tu AWS CLI."
fi

# Limpieza del archivo temporal
rm secrets_policy.json