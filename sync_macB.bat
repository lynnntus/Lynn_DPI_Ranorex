@echo off
cd /d "D:\RanorexProjects\Lynn_DPI_Ranorex"

set REMOTE_URL=
for /f "tokens=*" %%i in ('git remote get-url origin') do set REMOTE_URL=%%i
echo %REMOTE_URL% | findstr /i "https://" >nul
if not errorlevel 1 (
    git remote set-url origin git@github.com:lynnntus/Lynn_DPI_Ranorex.git
    echo Da chuyen sang SSH.
    echo.
)

echo.
echo ========================================
echo   PULL CODE TU GIT VE MAY B
echo ========================================
echo.
echo Dang kiem tra trang thai...
echo.

set STATUS=
for /f "tokens=*" %%i in ('git status --porcelain') do set STATUS=%%i
if not "%STATUS%"=="" (
    echo [CANH BAO] Ban co file chua push!
    echo.
    echo Cac file chua push:
    echo ========================================
    git status --short
    echo ========================================
    echo.
    echo Hay chay push_macB.bat truoc roi quay lai day.
    echo.
    pause
    goto :EOF
)

echo Khong co file thay doi local. Dang pull code moi tu Git...
echo.

git pull origin main
if errorlevel 1 (
    echo.
    echo ========================================
    echo   PULL THAT BAI!
    echo   Chup man hinh nay va gui cho may A.
    echo ========================================
    echo.
    pause
    goto :EOF
)

echo.
echo ========================================
echo   PULL THANH CONG!
echo   Hay mo Ranorex Studio:
echo     Build  -^>  Rebuild Solution
echo   roi chay test.
echo ========================================
echo.
pause
