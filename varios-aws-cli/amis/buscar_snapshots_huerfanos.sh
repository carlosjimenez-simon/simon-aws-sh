#!/bin/bash
echo "🔍 Buscando Snapshots huérfanos (de AMIs borradas)..."

# Obtener todos los snapshots del usuario
snaps=$(aws ec2 describe-snapshots --owner-ids self --query 'Snapshots[*].[SnapshotId,Description]' --output text)

while read -r snap_id desc; do
    # Verificar si la descripción contiene un ID de AMI (formato ami-xxxxxxxx)
    if [[ $desc =~ (ami-[a-zA-Z0-9]+) ]]; then
        ami_id=${BASH_REMATCH[1]}
        
        # Intentar buscar la AMI
        check_ami=$(aws ec2 describe-images --image-ids "$ami_id" 2>&1)
        
        if [[ $check_ami == *"InvalidAMIID.NotFound"* ]]; then
            echo "🚨 HUÉRFANO DETECTADO: Snapshot $snap_id (Pertenecía a la AMI borrada $ami_id)"
            echo "   Puedes borrarlo con: aws ec2 delete-snapshot --snapshot-id $snap_id"
            echo "----------------------------------------------------"
        fi
    fi
done <<< "$snaps"