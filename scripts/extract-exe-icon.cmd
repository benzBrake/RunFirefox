@echo off
setlocal
pushd "%~dp0.."
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0extract-exe-icon.ps1" -ExePath "%~1"
if errorlevel 1 pause
popd
endlocal
