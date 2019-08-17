@echo off

cd /d "%~dp0"
vagrant up

echo done...
choice /t 3 /d y /n >nul
