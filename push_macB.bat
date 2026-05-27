@echo off
chcp 65001 >nul
cd /d "D:\RanorexProjects\Lynn_DPI_Ranorex"

echo.
echo ========================================
echo   PUSH CODE TU MAY B LEN GIT
echo ========================================
echo.
echo Dang kiem tra thay doi...
echo.

git status --porcelain > "%TEMP%\git_status.tmp"
set /p STATUS=<"%TEMP%\git_status.tmp"
if "%STATUS%"=="" (
    echo Khong co file moi, khong can push.
    echo.
    goto :END
)

echo Cac file da thay doi:
echo ----------------------------------------
git status --short
echo ----------------------------------------
echo.

set /p CONFIRM="Ban co muon push cac file nay len Git? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo.
    echo Da huy. Khong push gi ca.
    goto :END
)

echo.
set /p MSG="Nhap mo ta ngan cho lan record nay: "
if "%MSG%"=="" set MSG=update from machine B

echo.
echo Dang push len Git...
echo.

git add -A
if errorlevel 1 (
    echo.
    echo [LOI] Git add that bai!
    echo Push THAT BAI! Chup man hinh nay va gui cho may A.
    goto :END
)

git commit -m "%MSG%"
if errorlevel 1 (
    echo.
    echo [LOI] Git commit that bai!
    echo Push THAT BAI! Chup man hinh nay va gui cho may A.
    goto :END
)

git push origin main
if errorlevel 1 (
    echo.
    echo ========================================
    echo   PUSH THAT BAI!
    echo   Chup man hinh nay va gui cho may A.
    echo ========================================
    goto :END
)

echo.
echo ========================================
echo   PUSH THANH CONG!
echo   Hay bao may A de sua code.
echo ========================================

:END
echo.
pause
