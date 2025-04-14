@echo off
setlocal EnableDelayedExpansion

echo GD savefile backup script v1.0, by BaconMania
echo.

::yes i vibecoded this script, smd

:: config paths
set "configFile=%APPDATA%\..\GDBackupSavedPath.txt"
set "autoFile=%APPDATA%\..\GDBackupAutoMode.txt"

:: check auto mode
if exist "%configFile%" (
    for /f "usebackq delims=" %%A in ("%configFile%") do set "savedPath=%%A"
    for /f "tokens=* delims= " %%B in ("%savedPath%") do set "savedPath=%%B"
)

if exist "%autoFile%" (
    for /f "usebackq delims=" %%A in ("%autoFile%") do set "autoMode=%%A"
)

:: if auto mode is enabled and savedPath is valid, do silent backup
if defined autoMode if "!autoMode!"=="1" if defined savedPath (
    call :doBackupSilent
    exit /b
)

:: interactive prompt
if defined savedPath (
    echo a saved backup path was found: [%savedPath%]
    echo.
    choice /m "use the saved backup path?"
    if errorlevel 2 goto askPath
    set "backupDir=%savedPath%"
    goto chooseAction
)

:askPath
echo.
echo select backup folder:
echo.
echo 1. enter path
echo 2. pick folder (recommended)
echo.
choice /c 12 /m "choose option"

if errorlevel 2 goto pickFolder
if errorlevel 1 goto manualInput

:manualInput
set /p "backupDir=enter path: "
goto askToSave

:pickFolder
set "vbsFile=%temp%\selectfolder.vbs"
echo Set objDialog = CreateObject("Shell.Application") > "%vbsFile%"
echo Set objFolder = objDialog.BrowseForFolder(0, "Select Backup Folder", 0, 0) >> "%vbsFile%"
echo If Not objFolder Is Nothing Then >> "%vbsFile%"
echo     Wscript.Echo objFolder.Items().Item().Path >> "%vbsFile%"
echo End If >> "%vbsFile%"
for /f "usebackq delims=" %%I in (`cscript //nologo "%vbsFile%"`) do set "backupDir=%%I"
del "%vbsFile%"

if not defined backupDir (
    echo no folder selected. exiting...
    pause
    exit /b
)

:askToSave
echo.
choice /m "do you want to save this path?"
if errorlevel 2 goto chooseAction
(
    echo %backupDir%
) > "%configFile%"
echo.
choice /m "enable auto mode? (useful if you want to just put this script in your startup folder)"
if errorlevel 2 goto chooseAction
(
    echo 1
) > "%autoFile%"
echo.
choice /m "do you want to copy this script to your startup folder?"
if errorlevel 2 goto chooseAction
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "scriptPath=%~f0"
copy /Y "%scriptPath%" "%startupFolder%\%~nx0" >nul
echo.
echo script copied to startup folder

:chooseAction
echo.
echo 1. backup save files
echo 2. restore from backup
echo.
choice /c 12 /m "choose option"
if errorlevel 2 goto restoreBackup
if errorlevel 1 goto doBackup

:doBackup
for /f %%A in ('powershell -nologo -command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "timestamp=%%A"
set "backupDirFull=%backupDir%\Backup_%timestamp%"

echo.
echo backing up to: [%backupDirFull%]
if not exist "%backupDirFull%" mkdir "%backupDirFull%"

echo.
copy /Y "%APPDATA%\..\Local\GeometryDash\CCLocalLevels.dat" "%backupDirFull%\CCLocalLevels.dat"
copy /Y "%APPDATA%\..\Local\GeometryDash\CCGameManager.dat" "%backupDirFull%\CCGameManager.dat"
echo.

echo backup complete^^!
echo.
pause
exit /b

:doBackupSilent
for /f %%A in ('powershell -nologo -command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "timestamp=%%A"
set "backupDirFull=%savedPath%\Backup_%timestamp%"

if not exist "!backupDirFull!" mkdir "!backupDirFull!"

copy /Y "%APPDATA%\..\Local\GeometryDash\CCLocalLevels.dat" "!backupDirFull%\CCLocalLevels.dat" >nul
copy /Y "%APPDATA%\..\Local\GeometryDash\CCGameManager.dat" "!backupDirFull%\CCGameManager.dat" >nul

exit /b

:restoreBackup
echo.
echo 1. restore latest backup
echo 2. choose backup to restore
echo.
choice /c 12 /m "choose restore option"
if errorlevel 2 goto pickBackup

:: restore latest
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
echo restoring from [%restoreDir%]...
echo.
copy /Y "%restoreDir%\CCLocalLevels.dat" "%APPDATA%\..\Local\GeometryDash\CCLocalLevels.dat"
copy /Y "%restoreDir%\CCGameManager.dat" "%APPDATA%\..\Local\GeometryDash\CCGameManager.dat"
echo.
echo restore complete^^!
echo.
pause
exit /b
