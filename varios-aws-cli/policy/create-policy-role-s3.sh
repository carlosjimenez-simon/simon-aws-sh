#!/bin/bash

# 1. Definir variables
POLICY_NAME="sm-dev-s3-gateway-multi-bucket-policy"
ROLE_NAME="sm-dev-core-ec2-role"

# Definimos los buckets que necesitas abarcar
BUCKET_LOGS="simon-camel-gateway-logs"
BUCKET_CACHE="simon-camel-gateway-cache"

echo "Creando el archivo de la política JSON para múltiples buckets..."

# 2. Crear el JSON permitiendo Listar, Leer, Escribir y Borrar en ambos buckets
cat <<EOF > s3_multi_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowListBuckets",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_LOGS",
                "arn:aws:s3:::$BUCKET_CACHE"
            ]
        },
        {
            "Sid": "AllowFullObjectActions",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_LOGS/*",
                "arn:aws:s3:::$BUCKET_CACHE/*"
            ]
        }
    ]
}
EOF

echo "Creando la nueva política en AWS..."

# 3. Crear la política en IAM
POLICY_ARN=$(aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document file://s3_multi_policy.json \
    --query 'Policy.Arn' \
    --output text)

if [ $? -eq 0 ]; then
    echo "¡Política Multi-Bucket creada con éxito! ARN: $POLICY_ARN"
    
    echo "Asociando la política al rol $ROLE_NAME..."
    
    # 4. Adjuntar la política al rol de la EC2
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "$POLICY_ARN"
    
    if [ $? -eq 0 ]; then
        echo "--------------------------------------------------------"
        echo "¡Coronamos, parce! El rol ya maneja logs y cache sin misterios."
        echo " Dale unos segundos de gabela para que AWS aplique y listo."
        echo "--------------------------------------------------------"
    else
        echo "Error al adjuntar la política al rol."
    fi
else
    echo "Hubo un error al crear la política en AWS. Verifica si ya existía una con ese nombre."
fi

# Limpieza
rm s3_multi_policy.json