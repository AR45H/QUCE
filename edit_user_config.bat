@echo off
:: This batch script prompts the user to select a directory and then 
:: looks for the file configs.user.ini in the selected directory and 
:: its subdirectories under steam_settings. It will read it and prompt 
:: the user to enter new values for account_name and account_steamid.

:: Call PowerShell to open a folder selection dialog
for /f "usebackq tokens=*" %%d in (`powershell -command "Add-Type -AssemblyName System.windows.forms; $fbd = New-Object System.Windows.Forms.FolderBrowserDialog; if($fbd.ShowDialog() -eq 'OK'){ $fbd.SelectedPath }"`) do (
    set "selectedDir=%%d"
)

:: Check if the configs.user.ini file exists in the selected directory
set "configFile=%selectedDir%\configs.user.ini"
if exist "%configFile%" (
    goto ReadConfig
)

:: If not found, search for steam_settings folder in subdirectories
set "foundConfigFile="
for /r "%selectedDir%" %%s in (steam_settings) do (
    if exist "%%s\configs.user.ini" (
        set "configFile=%%s\configs.user.ini"
        set "foundConfigFile=true"
        goto ReadConfig
    )
)

:: If the config file was not found
if not defined foundConfigFile (
    echo Config file not found in the selected directory or its steam_settings subdirectories.
    pause
    exit /b
)

:ReadConfig
:: Read account_name and account_steamid from the file
for /f "tokens=1,* delims==" %%A in ('type "%configFile%"') do (
    if "%%A"=="account_name" set currentAccountName=%%B
    if "%%A"=="account_steamid" set currentAccountSteamID=%%B
)

:: Display current values to the user
echo Current account_name: %currentAccountName%
echo Current account_steamid: %currentAccountSteamID%

:: Prompt the user for a new account_name using PowerShell GUI
for /f "tokens=*" %%A in ('powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null; [Microsoft.VisualBasic.Interaction]::InputBox('Enter new account name:', 'Account Name', '%currentAccountName%')"') do (
    set "newAccountName=%%A"
)

:: Check if user canceled account_name input
if "%newAccountName%"=="" (
    echo No account name provided. Operation canceled.
    pause
    exit /b
)

:: Prompt the user for a new account_steamid using PowerShell GUI
for /f "tokens=*" %%B in ('powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null; [Microsoft.VisualBasic.Interaction]::InputBox('Enter new account SteamID (numbers only):', 'Account SteamID', '%currentAccountSteamID%')"') do (
    set "newAccountSteamID=%%B"
)

:: Check if user canceled account_steamid input
if "%newAccountSteamID%"=="" (
    echo No SteamID provided. Operation canceled.
    pause
    exit /b
)

:: Update configs.user.ini file with new values
(for /f "tokens=1,* delims==" %%A in ('type "%configFile%"') do (
    if "%%A"=="account_name" (
        echo account_name=%newAccountName%
    ) else if "%%A"=="account_steamid" (
        echo account_steamid=%newAccountSteamID%
    ) else (
        echo %%A=%%B
    )
)) > "%configFile%.tmp"

:: Replace the old config file with the updated one
move /y "%configFile%.tmp" "%configFile%"

echo Configuration updated successfully.
pause
