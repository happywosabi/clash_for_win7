@echo off
taskkill /IM mihomo.exe /F >NUL 2>NUL
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >NUL
echo Mihomo stopped. Windows system proxy disabled.
pause
