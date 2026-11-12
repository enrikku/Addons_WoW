@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ConvertirImagen.ps1" %*
pause
