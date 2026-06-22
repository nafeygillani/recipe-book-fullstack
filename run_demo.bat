@echo off
cd /d "%~dp0"

start "Recipe Backend" cmd /k backend\start_backend.bat
timeout /t 5 > nul
start "Recipe Frontend" cmd /k frontend\start_frontend.bat
