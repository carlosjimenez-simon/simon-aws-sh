@echo off
setlocal enabledelayedexpansion

echo ----------------------------------------------------
echo 🚀 AWS ALB/NLB Listener Deleter (Windows Version)
echo ----------------------------------------------------

:: 1. Pedir el ARN al usuario
set /p LISTENER_ARN="Indique el ARN del Listener: "

:: Validar si el ARN está vacío
if "%LISTENER_ARN%"=="" (
    echo ❌ Error: El ARN no puede estar vacio.
    pause
    exit /b 1
)

:: 2. Confirmación de seguridad
echo.
echo ⚠️  ESTAS A PUNTO DE ELIMINAR EL SIGUIENTE LISTENER:
echo 👉 %LISTENER_ARN%
set /p CONFIRM="¿Estas seguro? (y/n): "

if /i "%CONFIRM%"=="y" (
    echo ⏳ Eliminando listener...
    
    :: 3. Ejecutar el comando de AWS CLI
    :: Nota: Asumimos que ya tienes configurado tu AWS_PROFILE en la terminal o por defecto
    aws elbv2 delete-listener --listener-arn "%LISTENER_ARN%"
    
    if !errorlevel! equ 0 (
        echo ✅ ¡Listo, parce! Listener eliminado correctamente.
    ) else (
        echo ❌ Hubo un error al intentar eliminar el listener. 
        echo Revisa tus permisos, el perfil de AWS o si el ARN es correcto.
    )
) else (
    echo 🚫 Operacion cancelada por el usuario.
)

echo ----------------------------------------------------
pause