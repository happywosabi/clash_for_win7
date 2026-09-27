@echo off
setlocal EnableExtensions
cd /d "%~dp0"

rem Important: %CD% has no trailing backslash after CD /D.
set "ROOT=%CD%"

"%ROOT%\mihomo.exe" -d "%ROOT%" -f "%ROOT%\config.yaml" >> "%ROOT%\mihomo.log" 2>&1
