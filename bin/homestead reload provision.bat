@echo off

cd /d "%~dp0"
vagrant reload --provision

echo done...
choice /t 3 /d y /n >nul
