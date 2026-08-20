@echo off
echo Starting English Core TaP...
start "" powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy','Bypass','-File','run_local.ps1' -WindowStyle Minimized"
timeout /t 3 >nul
start "" http://localhost:8080