@echo off
setlocal EnableExtensions
cd /d "%~dp0"

rem Use %CD% instead of %~dp0 for -d because %~dp0 ends with "\".
set "ROOT=%CD%"

title Mihomo Win7 Offline Starter v4

echo ===============================================
echo  Mihomo Win7 x64 Offline Starter v4
echo  Fixed Windows 7 path quoting
echo ===============================================
echo.

if not exist "%ROOT%\mihomo.exe" (
  echo [ERROR] mihomo.exe not found:
  echo         %ROOT%\mihomo.exe
  pause
  exit /b 1
)

if not exist "%ROOT%\ui\index.html" (
  echo [ERROR] ui\index.html is missing.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\Prepare_Config.ps1"
if errorlevel 1 (
  echo.
  echo [ERROR] Could not prepare config.yaml
  pause
  exit /b 1
)

echo.
echo [INFO] ROOT=%ROOT%
echo [INFO] Killing old Mihomo processes...
taskkill /IM mihomo.exe /F >NUL 2>NUL
ping 127.0.0.1 -n 2 >NUL

if exist "%ROOT%\mihomo.log" del /f /q "%ROOT%\mihomo.log" >NUL 2>NUL

echo [INFO] Starting Mihomo...
start "Mihomo" /min cmd /c call "%ROOT%\Run_Mihomo.cmd"

echo [INFO] Waiting for 127.0.0.1:9090 LISTENING...
set /a TRY=0

:WAIT_PORT
set /a TRY+=1
netstat -ano -p tcp 2>NUL | findstr /R /C:"127\.0\.0\.1:9090 .*LISTENING" >NUL
if not errorlevel 1 goto PORT_READY

if %TRY% GEQ 20 goto START_FAIL
ping 127.0.0.1 -n 2 >NUL
goto WAIT_PORT

:PORT_READY
echo [OK] Port 9090 is listening.
echo [INFO] Testing API without Authorization...

powershell -NoProfile -ExecutionPolicy Bypass -Command "$r=[System.Net.HttpWebRequest]::Create('http://127.0.0.1:9090/version');$r.Proxy=$null;try{$x=$r.GetResponse();$code=[int]$x.StatusCode;$x.Close();Write-Host ('HTTP ' + $code);if($code -eq 200){exit 0}else{exit 2}}catch{if($_.Exception.Response){Write-Host ('HTTP ' + [int]$_.Exception.Response.StatusCode)}else{Write-Host $_.Exception.Message};exit 1}"

if errorlevel 1 goto AUTH_FAIL

echo [OK] API works without authentication.

echo [INFO] Updating HTTP subscriptions for this startup...
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\Update_Providers.ps1"
if errorlevel 1 echo [WARNING] One or more subscriptions could not be updated. The UI will still open.

echo [INFO] Enabling Windows system proxy: 127.0.0.1:7890
if exist "%ROOT%\proxy-start-error.flag" del /f /q "%ROOT%\proxy-start-error.flag" >NUL 2>NUL
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "127.0.0.1:7890" /f >NUL 2>NUL
if errorlevel 1 goto PROXY_SERVER_FAIL
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "localhost;127.*;<local>" /f >NUL 2>NUL
if errorlevel 1 goto PROXY_FAIL
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f >NUL 2>NUL
if errorlevel 1 goto PROXY_FAIL
echo [OK] Windows system proxy enabled.
goto PROXY_DONE

:PROXY_SERVER_FAIL
> "%ROOT%\proxy-start-error.flag" echo ProxyServer
echo [WARNING] Windows refused to create the ProxyServer value.
echo [WARNING] Temporarily close antivirus software, retry in the UI, then turn it back on.
goto PROXY_FAIL_COMMON

:PROXY_FAIL
echo [WARNING] Windows system proxy could not be enabled.

:PROXY_FAIL_COMMON
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >NUL 2>NUL
if errorlevel 1 echo [WARNING] Could not disable the Windows system proxy. Run Stop_Mihomo.bat after checking registry permissions.

:PROXY_DONE
start "Mihomo Control" /min powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\Control_Server.ps1"

set "URL=http://127.0.0.1:9090/ui/?startup=%RANDOM%%RANDOM%"

if exist "%ProgramFiles(x86)%\360\360se6\Application\360se.exe" (
  start "" "%ProgramFiles(x86)%\360\360se6\Application\360se.exe" "%URL%"
  goto DONE
)
if exist "%ProgramFiles%\360\360se6\Application\360se.exe" (
  start "" "%ProgramFiles%\360\360se6\Application\360se.exe" "%URL%"
  goto DONE
)
if exist "%LOCALAPPDATA%\360Chrome\Chrome\Application\360chrome.exe" (
  start "" "%LOCALAPPDATA%\360Chrome\Chrome\Application\360chrome.exe" "%URL%"
  goto DONE
)
if exist "%ProgramFiles(x86)%\360Chrome\Chrome\Application\360chrome.exe" (
  start "" "%ProgramFiles(x86)%\360Chrome\Chrome\Application\360chrome.exe" "%URL%"
  goto DONE
)
if exist "%ProgramFiles%\360Chrome\Chrome\Application\360chrome.exe" (
  start "" "%ProgramFiles%\360Chrome\Chrome\Application\360chrome.exe" "%URL%"
  goto DONE
)

start "" "%URL%"

:DONE
echo.
echo [OK] Local UI:
echo      %URL%
echo.
echo [OK] API authentication disabled.
echo.
pause
exit /b 0

:AUTH_FAIL
echo.
echo [ERROR] 9090 is listening but API still requires authentication.
echo.
echo ==== Effective config ====
findstr /R /C:"^external-controller:" /C:"^secret:" /C:"^external-ui:" "%ROOT%\config.yaml"
echo.
echo ==== mihomo.log ====
if exist "%ROOT%\mihomo.log" type "%ROOT%\mihomo.log"
echo.
pause
exit /b 3

:START_FAIL
echo.
echo [ERROR] Mihomo did not listen on 127.0.0.1:9090.
echo.
echo Command used by Run_Mihomo.cmd:
echo   "%ROOT%\mihomo.exe" -d "%ROOT%" -f "%ROOT%\config.yaml"
echo.
echo ==== mihomo.log ====
if exist "%ROOT%\mihomo.log" (
  type "%ROOT%\mihomo.log"
) else (
  echo No mihomo.log was created.
)
echo.
pause
exit /b 2
