@echo off
setlocal
cd /d "%~dp0"
set "ROOT=%CD%"
title Mihomo v4 Diagnostics

echo ==== ROOT ====
echo %ROOT%
echo.

echo ==== Effective config ====
findstr /R /C:"^external-controller:" /C:"^secret:" /C:"^external-ui:" "%ROOT%\config.yaml"
echo.

echo ==== Ports ====
netstat -ano -p tcp | findstr ":9090"
netstat -ano -p tcp | findstr ":7890"
echo.

echo ==== API no-auth test ====
powershell -NoProfile -ExecutionPolicy Bypass -Command "$r=[System.Net.HttpWebRequest]::Create('http://127.0.0.1:9090/version');$r.Proxy=$null;try{$x=$r.GetResponse();$s=New-Object IO.StreamReader($x.GetResponseStream());Write-Host ('HTTP ' + [int]$x.StatusCode);Write-Host $s.ReadToEnd();$x.Close()}catch{if($_.Exception.Response){Write-Host ('HTTP ' + [int]$_.Exception.Response.StatusCode)};Write-Host $_.Exception.Message}"
echo.

echo ==== mihomo.log ====
if exist "%ROOT%\mihomo.log" type "%ROOT%\mihomo.log"
echo.
pause
