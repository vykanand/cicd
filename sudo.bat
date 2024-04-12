@echo off

:: Capture the current directory
set "current_directory=%cd%"

:: Prompt for UAC elevation and restart script with admin privileges
powershell -Command "Start-Process cmd -ArgumentList '/k cd /d %current_directory%' -Verb RunAs"
