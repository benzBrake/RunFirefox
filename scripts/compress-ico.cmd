@echo off
setlocal
pushd "%~dp0.."
if "%~1"=="" goto picker

:loop
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0compress-ico.ps1" -Paths "%~1"
if errorlevel 1 goto error
shift
if not "%~1"=="" goto loop
goto done

:picker
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0compress-ico.ps1"
if errorlevel 1 goto error

:done
popd
endlocal
exit /b 0

:error
pause
popd
endlocal
exit /b 1
