#!/bin/bash

# --- Script para borrar un Listener de AWS ALB ---

echo "----------------------------------------------------"
echo "🚀 AWS ALB Listener Deleter"
echo "----------------------------------------------------"

# 1. Pedir el ARN al usuario
read -p "Indique el ARN del Listener: " LISTENER_ARN

# Validar si el ARN está vacío
if [ -z "$LISTENER_ARN" ]; then
    echo "❌ Error: El ARN no puede estar vacío."
    exit 1
fi

# 2. Confirmación de seguridad
echo ""
echo "⚠️  ESTÁS A PUNTO DE ELIMINAR EL SIGUIENTE LISTENER:"
echo "👉 $LISTENER_ARN"
read -p "¿Estás seguro? (y/n): " CONFIRM

if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
    echo "⏳ Eliminando listener..."
    
    # 3. Ejecutar el comando de AWS CLI
    aws elbv2 delete-listener --listener-arn "$LISTENER_ARN"
    
    if [ $? -eq 0 ]; then
        echo "✅ ¡Listo, parce! Listener eliminado correctamente."
    else
        echo "❌ Hubo un error al intentar eliminar el listener. Revisa tus permisos o el ARN."
    fi
else
    echo "🚫 Operación cancelada por el usuario."
fi

echo "----------------------------------------------------"