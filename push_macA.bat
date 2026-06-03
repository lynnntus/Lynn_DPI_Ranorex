@echo off
chcp 65001 >nul 2>&1
cd /d "F:\RanorexProjects\Lynn_DPI_AT"

echo.
echo ========================================
echo   PUSH CODE TU MAY A LEN GIT
echo ========================================
echo.

echo [INFO] Branch hien tai:
git branch --show-current
echo.

echo [INFO] Trang thai file:
echo ----------------------------------------
git status --short
echo ----------------------------------------
echo.

set STATUS=
for /f "tokens=*" %%i in ('git status --porcelain') do set STATUS=%%i
if "%STATUS%"=="" (
    echo Khong co thay doi nao. Khong can push.
    echo.
    pause
    goto :EOF
)

set /p CONFIRM="Ban co muon push cac file nay len Git? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo.
    echo Da huy. Khong push gi ca.
    echo.
    pause
    goto :EOF
)

echo.
set /p MSG="Nhap commit message: "
if "%MSG%"=="" set MSG=update from machine A

echo.
echo Dang add va commit...
echo.

git add -A
if errorlevel 1 (
    echo.
    echo [LOI] Git add that bai!
    echo.
    pause
    goto :EOF
)

git commit -m "%MSG%"
if errorlevel 1 (
    echo.
    echo [LOI] Git commit that bai!
    echo.
    pause
    goto :EOF
)

echo.
echo Dang push len Git...
echo.

git push origin main
if errorlevel 1 (
    echo.
    echo ========================================
    echo   PUSH THAT BAI!
    echo   Kiem tra lai ket noi mang hoac remote.
    echo ========================================
    echo.
    pause
    goto :EOF
)

echo.
echo ========================================
echo   PUSH THANH CONG!
echo   May B co the chay sync_macB.bat
echo   de pull code moi ve.
echo ========================================
echo.
pause
