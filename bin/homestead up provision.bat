@echo off

cd /d "%~dp0"
vagrant up --provision

echo done...
choice /t 3 /d y /n >nul
