@echo off
cd /d "%~dp0"
start "O11A1 prototype server" /min python -m http.server 4173
timeout /t 1 >nul
start "" http://localhost:4173
