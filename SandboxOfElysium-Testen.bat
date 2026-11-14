@echo off
setlocal EnableExtensions DisableDelayedExpansion
title SandboxOfElysium - Lokale Entwicklung testen
if not exist "%~dp0tools\test-development.ps1" goto missing
pushd "%~dp0"
if errorlevel 1 goto directory_error
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\test-development.ps1" %*
set "soeTestExit=%ERRORLEVEL%"
popd
if not "%soeTestExit%"=="0" goto failed
endlocal & exit /b 0

:missing
echo FEHLER: tools\test-development.ps1 fehlt neben dieser Batchdatei.
echo Bitte die BAT im vollstaendigen Sandbox-Projektordner starten.
set "soeTestExit=1"
goto failed

:directory_error
echo FEHLER: Der Sandbox-Projektordner kann nicht geoeffnet werden.
set "soeTestExit=1"

:failed
echo.
echo Teststart abgebrochen. Die normale Spielinstallation wurde nicht eingerichtet.
if not defined SOE_TEST_NO_PAUSE pause
endlocal & exit /b %soeTestExit%
