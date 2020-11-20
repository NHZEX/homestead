@echo off

cd /d "%~dp0"
vagrant provision

echo done...
choice /t 3 /d y /n >nul
