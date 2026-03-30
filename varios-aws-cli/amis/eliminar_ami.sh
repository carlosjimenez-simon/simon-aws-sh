#!/bin/bash

# --- Script para eliminar una AMI específica y su Snapshot ---

echo "----------------------------------------------------"
echo "🎯 AWS EC2 AMI Deleter (Precisión)"
echo "----------------------------------------------------"

# 1. Pedir el AMI ID
read -p "Ingrese el ID de la AMI (ej: ami-0123456789abcdef0): " AMI_ID

# Validar que no esté vacío y que empiece por 'ami-'
if [[ -z "$AMI_ID" || ! "$AMI_ID" =~ ^ami- ]]; then
    echo "❌ Error: El ID debe empezar con 'ami-'. Intenta de nuevo."
    exit 1
fi

echo "🔍 Buscando información de la AMI..."

# 2. Obtener el ID del Snapshot asociado antes de borrar la AMI
# (Si borras la AMI primero, luego es un camello saber qué snapshot era)
SNAP_ID=$(aws ec2 describe-images --image-ids "$AMI_ID" \
    --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId' --output text 2>/dev/null)

if [ "$?" != "0" ] || [ "$SNAP_ID" == "None" ] || [ -z "$SNAP_ID" ]; then
    echo "⚠️  No se encontró un snapshot asociado o la AMI no existe."
    # No salimos por si igual quieres intentar borrar la AMI
else
    echo "📦 Snapshot detectado: $SNAP_ID"
fi

# 3. Confirmación final
read -p "⚠️  ¿Seguro que quieres borrar $AMI_ID? (y/n): " CONFIRM

if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
    
    # A. Deregister de la AMI
    echo "💥 Eliminando AMI..."
    aws ec2 deregister-image --image-id "$AMI_ID"
    
    if [ $? -eq 0 ]; then
        echo "✅ AMI eliminada con éxito."
        
        # B. Borrar el Snapshot (Solo si existía)
        if [[ ! -z "$SNAP_ID" && "$SNAP_ID" != "None" ]]; then
            echo "⚙️  Limpiando el Snapshot para que no te cobren..."
            sleep 2 # Un respiro para que AWS procese el deregister
            aws ec2 delete-snapshot --snapshot-id "$SNAP_ID"
            
            if [ $? -eq 0 ]; then
                echo "✅ Snapshot $SNAP_ID eliminado."
            else
                echo "❌ No se pudo borrar el snapshot. Puede que aún esté en uso o ya no exista."
            fi
        fi
    else
        echo "❌ Falló la eliminación de la AMI. Revisa el ID o tus permisos."
    fi
else
    echo "🚫 Operación cancelada."
fi

echo "----------------------------------------------------"