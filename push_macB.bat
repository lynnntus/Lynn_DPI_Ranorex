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
echo   PUSH CODE TU MAY B LEN GIT
echo ========================================
echo.
echo Dang kiem tra thay doi...
echo.

set STATUS=
for /f "tokens=*" %%i in ('git status --porcelain') do set STATUS=%%i
if "%STATUS%"=="" (
    echo Khong co file moi, khong can push.
    echo.
    pause
    goto :EOF
)

echo Cac file da thay doi:
echo ========================================
git status --short
echo ========================================
echo.

set /p CONFIRM="Ban co muon push cac file nay len Git? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo.
    echo Da huy. Khong push gi ca.
    echo.
    pause
    goto :EOF
)

echo.
set /p MSG="Nhap mo ta ngan cho lan record nay: "
if "%MSG%"=="" set MSG=update from machine B

echo.
echo Dang add va commit...
echo.

git add -A
if errorlevel 1 (
    echo.
    echo [LOI] Git add that bai!
    echo Push THAT BAI! Chup man hinh nay va gui cho may A.
    echo.
    pause
    goto :EOF
)

git commit -m "%MSG%"
if errorlevel 1 (
    echo.
    echo [LOI] Git commit that bai!
    echo Push THAT BAI! Chup man hinh nay va gui cho may A.
    echo.
    pause
    goto :EOF
)

echo.
echo Dang pull --rebase truoc khi push...
echo.

git pull --rebase origin main
if errorlevel 1 (
    echo.
    echo ========================================
    echo   PULL --REBASE THAT BAI ^(co conflict^)!
    echo.
    echo   Cach xu ly:
    echo     1. Mo VS Code, chon Accept Current/Incoming/Both
    echo     2. git add .
    echo     3. git rebase --continue
    echo     4. git push origin main
    echo.
    echo   Neu roi qua thi chay: git rebase --abort
    echo ========================================
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
    echo   Chup man hinh nay va gui cho may A.
    echo ========================================
    echo.
    pause
    goto :EOF
)

echo.
echo ========================================
echo   PUSH THANH CONG!
echo   Hay bao may A de sua code.
echo ========================================
echo.
pause
