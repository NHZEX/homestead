@echo off

cd /d "%~dp0"
vagrant halt

echo done...
choice /t 3 /d y /n >nul
