@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0composer.ps1" %*
exit /b %ERRORLEVEL%
