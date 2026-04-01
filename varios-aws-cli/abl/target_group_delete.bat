@echo off
setlocal enabledelayedexpansion

:: --- CONFIGURACIÓN (Debe coincidir con el nombre que usaste para crear) ---
set TG_NAME=sm-dev-refactor-traccar-gpstk-tg
set AWS_PROFILE=AdministratorAccess-707925622299
set AWS_REGION=us-east-1

echo ----------------------------------------------------
echo 🔍 Buscando el ARN del Target Group: %TG_NAME%...
echo ----------------------------------------------------

:: 1. Buscar el ARN por el nombre
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups ^
    --names %TG_NAME% ^
    --region %AWS_REGION% ^
    --profile %AWS_PROFILE% ^
    --query "TargetGroups[0].TargetGroupArn" --output text 2^>nul') do set TG_ARN=%%i

:: Validar si el ARN existe
if "%TG_ARN%"=="" (
    echo ❌ Error: No se encontro el Target Group '%TG_NAME%'.
    echo Tal vez ya fue eliminado o el nombre es incorrecto.
    pause
    exit /b 1
)

if "%TG_ARN%"=="None" (
    echo ❌ Error: No se pudo obtener el ARN.
    pause
    exit /b 1
)

echo ✅ ARN encontrado: %TG_ARN%

:: 2. Confirmación de seguridad
echo.
echo ⚠️  ¡PILAS! Estas a punto de borrar el Target Group.
echo Esto desconectara cualquier trafico de los GPS asociados.
set /p CONFIRM="¿Estas seguro de eliminarlo? (y/n): "

if /i "%CONFIRM%"=="y" (
    echo ⏳ Eliminando Target Group...
    
    :: 3. Ejecutar el borrado
    aws elbv2 delete-target-group ^
        --target-group-arn "%TG_ARN%" ^
        --region %AWS_REGION% ^
        --profile %AWS_PROFILE%

    if !errorlevel! equ 0 (
        echo ✅ Target Group eliminado correctamente.
    ) else (
        echo ❌ Error al intentar eliminar el TG. 
        echo Nota: Si el TG esta siendo usado por un Listener, primero debes borrar el Listener.
    )
) else (
    echo 🚫 Operacion cancelada por el usuario.
)

echo ----------------------------------------------------
pause