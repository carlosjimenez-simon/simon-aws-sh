@echo off
setlocal enabledelayedexpansion

:: --- CONFIGURACIÓN ---
set TG_NAME=sm-dev-refactor-traccar-gpstk-tg
set ASG_NAME=sm-dev-refactor-gps
set VPC_ID=vpc-04c3946b71fc75d88
set PORT=5027
set AWS_PROFILE=AdministratorAccess-707925622299
set AWS_REGION=us-east-1

echo ------------------------------------------------
echo 🎯 Paso 1: Creando Target Group para Traccar
echo ------------------------------------------------

:: 1. Crear el Target Group y capturar el ARN
for /f "tokens=*" %%i in ('aws elbv2 create-target-group ^
    --name %TG_NAME% ^
    --protocol TCP ^
    --port %PORT% ^
    --vpc-id %VPC_ID% ^
    --target-type instance ^
    --region %AWS_REGION% ^
    --profile %AWS_PROFILE% ^
    --query "TargetGroups[0].TargetGroupArn" --output text') do set TG_ARN=%%i

:: Validar si el ARN se obtuvo correctamente
if "%TG_ARN%"=="" (
    echo ❌ Error al crear el Target Group.
    pause
    exit /b 1
)

if "%TG_ARN%"=="None" (
    echo ❌ Error: El comando devolvio 'None'. Revisa los parametros.
    pause
    exit /b 1
)

echo ✅ Target Group creado: %TG_ARN%

echo ⚙️ Configurando atributos criticos (Cross-Zone y Proxy Mode)...

:: 2. Modificar atributos:
:: - load_balancing.cross_zone.enabled=true
:: - preserve_client_ip.enabled=false
aws elbv2 modify-target-group-attributes ^
    --target-group-arn "%TG_ARN%" ^
    --attributes ^
        Key=load_balancing.cross_zone.enabled,Value=true ^
        Key=preserve_client_ip.enabled,Value=false ^
    --region %AWS_REGION% ^
    --profile %AWS_PROFILE%

if !errorlevel! equ 0 (
    echo ✅ Atributos configurados correctamente.
) else (
    echo ⚠️ Error al configurar atributos, revisa los permisos del perfil.
)

echo ------------------------------------------------
echo 🚀 ¡TARGET GROUP LISTO Y OPTIMIZADO!
echo Siguiente paso: traccar_nbl_create_paso_2_asoc_asg.bat
echo ARN: %TG_ARN%
echo ------------------------------------------------
pause