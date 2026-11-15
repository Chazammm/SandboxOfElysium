@echo off
setlocal EnableExtensions DisableDelayedExpansion
title SandboxOfElysium - Test local development
if not exist "%~dp0tools\test-development.ps1" goto missing
pushd "%~dp0"
if errorlevel 1 goto directory_error
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\test-development.ps1" %*
set "soeTestExit=%ERRORLEVEL%"
popd
if not "%soeTestExit%"=="0" goto failed
endlocal & exit /b 0

:missing
echo ERROR: tools\test-development.ps1 is missing beside this batch file.
echo Run the BAT from the complete Sandbox project folder.
set "soeTestExit=1"
goto failed

:directory_error
echo ERROR: Cannot open the Sandbox project folder.
set "soeTestExit=1"

:failed
echo.
echo Test launch aborted. The regular game installation was not configured.
if not defined SOE_TEST_NO_PAUSE pause
endlocal & exit /b %soeTestExit%
