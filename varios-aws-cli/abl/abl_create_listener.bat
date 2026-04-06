@echo off
setlocal enabledelayedexpansion

:: --- CONFIGURACIÓN ---
set LB_ARN=arn:aws:elasticloadbalancing:us-east-1:707925622299:loadbalancer/net/sm-dev-refactor-public-gps-lb/d8c57598fdc399c8
set PORT=5027
set TG_ARN=arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/sm-dev-refactor-traccar-gpstk-tg/794cd9ea42389b26
set AWS_PROFILE=AdministratorAccess-707925622299
set AWS_REGION=us-east-1

echo 🔍 Verificando si el listener en el puerto %PORT% ya existe...

:: Ejecutamos el comando para buscar el listener existente
for /f "tokens=*" %%i in ('aws elbv2 describe-listeners --load-balancer-arn %LB_ARN% --region %AWS_REGION% --profile %AWS_PROFILE% --query "Listeners[?Port==`%PORT%`].ListenerArn" --output text') do set EXISTING_LISTENER=%%i

if "%EXISTING_LISTENER%"=="" (
    echo 🔗 Creando Listener TCP en puerto %PORT%...
    aws elbv2 create-listener ^
        --load-balancer-arn %LB_ARN% ^
        --protocol TCP ^
        --port %PORT% ^
        --default-actions Type=forward,TargetGroupArn=%TG_ARN% ^
        --region %AWS_REGION% ^
        --profile %AWS_PROFILE%
) else (
    echo ⚠️ El listener en el puerto %PORT% ya existe. Saltando creacion.
)

echo ------------------------------------------------
echo ✅ ¡PROCESO FINALIZADO!

:: Obtener el DNS Name
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --load-balancer-arns %LB_ARN% --region %AWS_REGION% --profile %AWS_PROFILE% --query "LoadBalancers[0].DNSName" --output text') do set DNS_NAME=%%i

echo 🔗 DNS: %DNS_NAME%
echo Siguiente paso: traccar_nbl_create_paso_4_verify_nbl.bat
echo ------------------------------------------------
pause