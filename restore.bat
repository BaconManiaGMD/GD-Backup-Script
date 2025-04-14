@echo off
setlocal EnableDelayedExpansion

echo GD save file restore script v1.0, by BaconMania.\
echo.

::yes I vibecoded this script, smd

:: Config path
set "configFile=%APPDATA%\..\GDBackupSavedPath.txt"

:: Get saved backup path
if not exist "%configFile%" (
    echo no saved path found. nun the main backup script first to set it.
    pause
    exit /b
)

for /f "usebackq delims=" %%A in ("%configFile%") do set "backupDir=%%A"
if not defined backupDir (
    echo saved path is empty or invalid.
    pause
    exit /b
)

:: Restore prompt
echo.
echo backup directory: [%backupDir%]
echo.
echo 1. restore latest backup
echo 2. choose backup
echo.
choice /c 12 /m "choose restore option"
if errorlevel 2 goto pickBackup

:: Restore latest
for /f "delims=" %%F in ('dir "%backupDir%" /b /ad /o-d ^| findstr /i "Backup_"') do (
    set "latest=%%F"
    goto :gotLatest
)
:gotLatest
if not defined latest (
    echo no backups found.
    pause
    exit /b
)
set "restoreDir=%backupDir%\%latest%"
goto doRestore

:pickBackup
echo.
echo available backups:
echo.
set i=0
for /f "delims=" %%D in ('dir "%backupDir%" /b /ad ^| findstr /i "Backup_"') do (
    set /a i+=1
    echo !i!. %%D
    set "bkp[!i!]=%%D"
)
echo.
set /p choice=choose backup:  
set "restoreDir=%backupDir%\!bkp[%choice%]!"
goto doRestore

:doRestore
echo.
echo restoring from: [%restoreDir%]...
echo.
copy /Y "%restoreDir%\CCLocalLevels.dat" "%APPDATA%\..\Local\GeometryDash\CCLocalLevels.dat"
copy /Y "%restoreDir%\CCGameManager.dat" "%APPDATA%\..\Local\GeometryDash\CCGameManager.dat"
echo.
echo restore complete^^!
echo.
pause
exit /b
