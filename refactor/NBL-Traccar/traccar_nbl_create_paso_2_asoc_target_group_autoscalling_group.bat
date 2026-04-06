@echo off
setlocal enabledelayedexpansion

:: --- CONFIGURACIÓN ---
set ASG_NAME=sm-dev-refactor-gps
set TG_NAME=sm-dev-refactor-traccar-gpstk-tg
set AWS_PROFILE=AdministratorAccess-707925622299
set AWS_REGION=us-east-1

echo ----------------------------------------------------
echo 🔍 Buscando el ARN del Target Group: %TG_NAME%...
echo ----------------------------------------------------

:: 1. Buscar el ARN automáticamente por el nombre
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups ^
    --names %TG_NAME% ^
    --region %AWS_REGION% ^
    --profile %AWS_PROFILE% ^
    --query "TargetGroups[0].TargetGroupArn" --output text 2^>nul') do set TG_ARN=%%i

:: Validar si el ARN existe
if "%TG_ARN%"=="" (
    echo ❌ Error: No se encontro un Target Group con el nombre '%TG_NAME%'.
    pause
    exit /b 1
)

if "%TG_ARN%"=="None" (
    echo ❌ Error: El Target Group '%TG_NAME%' no existe en esta region/perfil.
    pause
    exit /b 1
)

echo ✅ ARN encontrado: %TG_ARN%
echo 🔗 Asociando el Target Group con el Auto Scaling Group (%ASG_NAME%)...

:: 2. Ejecutar la asociación con el ASG
aws autoscaling attach-load-balancer-target-groups ^
    --auto-scaling-group-name %ASG_NAME% ^
    --target-group-arns %TG_ARN% ^
    --region %AWS_REGION% ^
    --profile %AWS_PROFILE%

if !errorlevel! equ 0 (
    echo ----------------------------------------------------
    echo ✅ ¡Exito! El ASG ahora registrara automaticamente 
    echo sus instancias en este Target Group.
    echo ----------------------------------------------------
) else (
    echo ❌ Error al asociar el TG con el ASG. Revisa permisos o el nombre del ASG.
)

pause