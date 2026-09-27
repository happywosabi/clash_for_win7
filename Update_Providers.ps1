param([string]$ApiBase = "http://127.0.0.1:9090")

$ErrorActionPreference = "Stop"
$apiBase = $ApiBase.TrimEnd('/')
Add-Type -AssemblyName System.Web.Extensions
$serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$serializer.MaxJsonLength = 16777216

function Invoke-ControllerRequest([string]$Method, [string]$Path) {
    $request = [System.Net.HttpWebRequest]::Create($apiBase + $Path)
    $request.Proxy = $null
    $request.Method = $Method
    $request.Timeout = 20000
    $request.ReadWriteTimeout = 20000
    if ($Method -eq "PUT") { $request.ContentLength = 0 }
    $response = $request.GetResponse()
    try {
        if ($Method -eq "GET") {
            $reader = New-Object System.IO.StreamReader($response.GetResponseStream(), [System.Text.Encoding]::UTF8)
            return $reader.ReadToEnd()
        }
    } finally {
        $response.Close()
    }
}

try {
    $providers = $null
    for ($attempt = 0; $attempt -lt 3; $attempt++) {
        try {
            $body = Invoke-ControllerRequest "GET" "/providers/proxies"
            $data = $serializer.DeserializeObject($body)
            if (!($data -is [System.Collections.IDictionary]) -or !($data['providers'] -is [System.Collections.IDictionary])) {
                throw "Invalid proxy provider response."
            }
            $providers = $data['providers']
        } catch {
            if ($attempt -eq 2) { throw }
            Start-Sleep -Seconds 1
            continue
        }
        $hasHttp = $false
        foreach ($name in $providers.Keys) {
            $provider = $providers[$name]
            if ($provider -is [System.Collections.IDictionary] -and [string]$provider['vehicleType'] -ieq 'HTTP') {
                $hasHttp = $true
                break
            }
        }
        if ($hasHttp -or $attempt -eq 2) { break }
        Start-Sleep -Seconds 1
    }

    $updated = 0
    $failed = 0
    foreach ($name in @($providers.Keys | Sort-Object)) {
        $provider = $providers[$name]
        if (!($provider -is [System.Collections.IDictionary])) { continue }
        $vehicleType = [string]$provider['vehicleType']
        if ($vehicleType -and $vehicleType -ine 'HTTP') { continue }
        if (!$vehicleType -and $name -eq 'default') { continue }
        try {
            $path = "/providers/proxies/" + [System.Uri]::EscapeDataString([string]$name)
            Invoke-ControllerRequest "PUT" $path | Out-Null
            Write-Host ("[OK] Subscription update requested: " + $name)
            $updated++
        } catch {
            Write-Host ("[WARNING] Subscription update failed: " + $name + " (" + $_.Exception.Message + ")")
            $failed++
        }
    }
    if ($updated -eq 0 -and $failed -eq 0) { Write-Host "[INFO] No HTTP subscriptions found." }
    if ($failed -gt 0) { exit 1 }
} catch {
    Write-Host ("[WARNING] Could not check subscriptions: " + $_.Exception.Message)
    exit 1
}
