$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$settings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$startupError = Join-Path $root "proxy-start-error.flag"
$allowedOrigin = "http://127.0.0.1:9090"
$port = 9091

Add-Type -AssemblyName System.Web.Extensions
$serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class ProxySettingsChanged {
    [DllImport("wininet.dll", SetLastError = true)]
    public static extern bool InternetSetOption(IntPtr handle, int option, IntPtr buffer, int length);
    public static void Notify() {
        InternetSetOption(IntPtr.Zero, 39, IntPtr.Zero, 0);
        InternetSetOption(IntPtr.Zero, 37, IntPtr.Zero, 0);
    }
}
public class ControlStatus {
    public bool coreRunning;
    public bool proxyEnabled;
    public string proxyServer;
    public bool startupError;
}
public class ControlResult {
    public bool ok;
    public string message;
    public string code;
}
'@

function Test-Core {
    try {
        $request = [System.Net.HttpWebRequest]::Create("http://127.0.0.1:9090/version")
        $request.Proxy = $null
        $request.Timeout = 800
        $response = $request.GetResponse()
        $response.Close()
        return $true
    } catch {
        return $false
    }
}

function Get-Status {
    $registry = Get-ItemProperty -Path $settings
    $status = New-Object ControlStatus
    $status.coreRunning = Test-Core
    $status.proxyEnabled = ($registry.ProxyEnable -eq 1)
    $status.proxyServer = [string]$registry.ProxyServer
    $status.startupError = Test-Path $startupError
    return $status
}

function New-Result($ok, $message, $code = '') {
    $result = New-Object ControlResult
    $result.ok = [bool]$ok
    $result.message = [string]$message
    $result.code = [string]$code
    return $result
}

function Notify-ProxyChange {
    [ProxySettingsChanged]::Notify()
}

function Disable-Proxy {
    try {
        New-ItemProperty -Path $settings -Name ProxyEnable -Value 0 -PropertyType DWord -Force | Out-Null
        Notify-ProxyChange
        return (New-Result $true "系统代理已关闭")
    } catch {
        return (New-Result $false ("关闭系统代理失败：" + $_.Exception.Message))
    }
}

function Enable-Proxy {
    if (!(Test-Core)) {
        return (New-Result $false "Mihomo 内核未运行，无法启用系统代理")
    }
    try {
        New-ItemProperty -Path $settings -Name ProxyServer -Value "127.0.0.1:7890" -PropertyType String -Force | Out-Null
    } catch {
        Set-Content -Path $startupError -Value "ProxyServer" -ErrorAction SilentlyContinue
        return (New-Result $false "系统拒绝创建 ProxyServer。请暂时关闭杀毒软件后重试，完成后重新开启。" "proxyserver-denied")
    }
    try {
        New-ItemProperty -Path $settings -Name ProxyOverride -Value "localhost;127.*;<local>" -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $settings -Name ProxyEnable -Value 1 -PropertyType DWord -Force | Out-Null
        Notify-ProxyChange
        if (Test-Path $startupError) { Remove-Item $startupError -Force }
        return (New-Result $true "系统代理已启用")
    } catch {
        return (New-Result $false ("启用系统代理失败：" + $_.Exception.Message))
    }
}

function Stop-Core {
    try {
        Get-Process -Name mihomo -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop
        Start-Sleep -Milliseconds 150
        if (Get-Process -Name mihomo -ErrorAction SilentlyContinue) {
            return (New-Result $false "Mihomo 内核未能停止，请运行 Stop_Mihomo.bat")
        }
        return (New-Result $true "系统代理已关闭，Mihomo 内核已停止")
    } catch {
        return (New-Result $false ("Mihomo 内核未能停止：" + $_.Exception.Message))
    }
}

function Send-Response($stream, $code, $body, $origin) {
    $reason = @{ 200 = "OK"; 204 = "No Content"; 400 = "Bad Request"; 403 = "Forbidden"; 404 = "Not Found"; 500 = "Internal Server Error" }[$code]
    $payload = [System.Text.Encoding]::UTF8.GetBytes($body)
    $headers = "HTTP/1.1 $code $reason`r`nContent-Type: application/json; charset=utf-8`r`nContent-Length: $($payload.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n"
    if ($origin -eq $allowedOrigin) {
        $headers += "Access-Control-Allow-Origin: $allowedOrigin`r`nAccess-Control-Allow-Methods: GET, POST, OPTIONS`r`nAccess-Control-Allow-Headers: X-Mihomo-Control`r`nVary: Origin`r`n"
    }
    $headers += "`r`n"
    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
    $stream.Write($headerBytes, 0, $headerBytes.Length)
    if ($payload.Length -gt 0) { $stream.Write($payload, 0, $payload.Length) }
    $stream.Flush()
}

$listener = New-Object System.Net.Sockets.TcpListener -ArgumentList @([System.Net.IPAddress]::Loopback, $port)
$listener.Start()
Notify-ProxyChange
$stopServer = $false
try {
    while (!$stopServer) {
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 5000
            $client.SendTimeout = 5000
            $stream = $client.GetStream()
            $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)
            $line = $reader.ReadLine()
            if ([string]::IsNullOrEmpty($line)) { continue }
            $parts = $line.Split(' ')
            if ($parts.Length -lt 2) { Send-Response $stream 400 '{}' ''; continue }
            $headers = @{}
            for ($i = 0; $i -lt 40; $i++) {
                $line = $reader.ReadLine()
                if ([string]::IsNullOrEmpty($line)) { break }
                $separator = $line.IndexOf(':')
                if ($separator -gt 0) { $headers[$line.Substring(0, $separator).ToLowerInvariant()] = $line.Substring($separator + 1).Trim() }
            }
            $origin = $headers['origin']
            $method = $parts[0]
            $path = $parts[1].Split('?')[0]
            if ($origin -and $origin -ne $allowedOrigin) {
                Send-Response $stream 403 '{}' $origin
            } elseif ($method -eq 'OPTIONS') {
                if ($origin -eq $allowedOrigin) { Send-Response $stream 204 '' $origin }
                else { Send-Response $stream 403 '{}' $origin }
            } elseif ($method -eq 'GET' -and $path -eq '/status') {
                Send-Response $stream 200 ($serializer.Serialize((Get-Status))) $origin
            } elseif ($method -eq 'POST' -and $origin -eq $allowedOrigin -and $headers['x-mihomo-control'] -eq '1') {
                if ($path -eq '/proxy/disable') {
                    $result = Disable-Proxy
                } elseif ($path -eq '/proxy/enable') {
                    $result = Enable-Proxy
                } elseif ($path -eq '/core/stop') {
                    $result = Disable-Proxy
                    if ($result.ok) { $result = Stop-Core }
                } else {
                    Send-Response $stream 404 '{}' $origin
                    continue
                }
                Send-Response $stream 200 ($serializer.Serialize($result)) $origin
                if ($path -eq '/core/stop' -and $result.ok) {
                    $stopServer = $true
                }
            } else {
                Send-Response $stream 403 '{}' $origin
            }
        } catch {
            Add-Content -Path (Join-Path $root 'control.log') -Value ((Get-Date).ToString('s') + ' ' + $_.ToString()) -ErrorAction SilentlyContinue
            try { Send-Response $stream 500 '{"ok":false}' $origin } catch {}
        } finally {
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
}
