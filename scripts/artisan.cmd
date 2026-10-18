@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0artisan.ps1" %*
exit /b %ERRORLEVEL%
