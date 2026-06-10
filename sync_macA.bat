@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
cd /d "F:\RanorexProjects\Lynn_DPI_AT"

echo.
echo ========================================
echo   PULL CODE TU GIT VE MAY A
echo ========================================
echo.

echo [INFO] Branch hien tai:
git branch --show-current
echo.

echo [INFO] Trang thai file local:
echo ----------------------------------------
git status --short
echo ----------------------------------------
echo.

set STATUS=
for /f "tokens=*" %%i in ('git status --porcelain') do set STATUS=%%i
if not "!STATUS!"=="" (
    echo [CANH BAO] Ban co file chua commit!
    echo.
    echo Chon cach xu ly:
    echo   1 = Stash tam ^(luu lai, pull, roi restore^)
    echo   2 = Huy va thoat ^(tu commit/push truoc^)
    echo.
    set /p CHOICE="Chon (1 hoac 2): "
    if /i "!CHOICE!"=="1" goto :STASH
    echo.
    echo Da huy. Hay chay push_macA.bat truoc roi quay lai.
    echo.
    pause
    goto :EOF
)

goto :PULL

:STASH
echo.
echo Dang stash cac thay doi local...
git stash push -m "auto-stash truoc khi pull"
if errorlevel 1 (
    echo.
    echo [LOI] Git stash that bai!
    echo.
    pause
    goto :EOF
)
echo Stash thanh cong.
echo.

:PULL
echo Dang fetch va pull (rebase) code moi tu Git...
echo.

git fetch origin
if errorlevel 1 (
    echo.
    echo [LOI] Git fetch that bai! Kiem tra ket noi mang.
    echo.
    pause
    goto :EOF
)

git pull --rebase origin main
if errorlevel 1 (
    echo.
    echo ========================================
    echo   PULL THAT BAI!
    echo.
    echo   Neu co conflict, hay xu ly bang:
    echo     1. Mo file conflict trong editor
    echo     2. Sua noi dung cho dung
    echo     3. git add ^<file^>
    echo     4. git rebase --continue
    echo.
    echo   Hoac huy rebase:
    echo     git rebase --abort
    echo ========================================
    echo.
    pause
    goto :EOF
)

:: Restore stash neu co
git stash list | findstr "auto-stash truoc khi pull" >nul 2>&1
if not errorlevel 1 (
    echo.
    echo Dang restore stash...
    git stash pop
    if errorlevel 1 (
        echo.
        echo [CANH BAO] Stash pop co conflict!
        echo Hay mo code va resolve conflict thu cong.
        echo.
        echo Cac file conflict:
        git diff --name-only --diff-filter=U
        echo.
        echo Stash van con trong 'git stash list'.
        echo.
        pause
        goto :EOF
    )
    echo Restore stash thanh cong.
)

echo.
echo ========================================
echo   SYNC THANH CONG!
echo   Hay mo Ranorex Studio:
echo     Build  -^>  Rebuild Solution
echo   roi chay test.
echo ========================================
echo.
pause
