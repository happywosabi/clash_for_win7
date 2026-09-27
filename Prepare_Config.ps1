$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$template = Join-Path $root "config.template.yaml"
$config = Join-Path $root "config.yaml"

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

if (!(Test-Path $config)) {
    Write-Host ""
    Write-Host "First run: paste your Clash/Mihomo subscription URL." -ForegroundColor Cyan
    $url = Read-Host "Subscription URL"
    if ([string]::IsNullOrWhiteSpace($url)) { throw "Subscription URL cannot be empty." }
    if ($url.Contains('"')) { throw 'The URL contains a double quote (").' }

    $raw = [System.IO.File]::ReadAllText($template, [System.Text.Encoding]::UTF8)
    $raw = $raw.Replace("__SUBSCRIPTION_URL__", $url.Trim())
    Write-Utf8NoBom $config $raw
} else {
    $raw = [System.IO.File]::ReadAllText($config, [System.Text.Encoding]::UTF8)

    if ([regex]::IsMatch($raw, '(?m)^[ \t]*external-controller[ \t]*:.*$')) {
        $raw = [regex]::Replace($raw, '(?m)^[ \t]*external-controller[ \t]*:.*$', 'external-controller: 127.0.0.1:9090')
    } else {
        $raw = "external-controller: 127.0.0.1:9090`r`n" + $raw
    }

    if ([regex]::IsMatch($raw, '(?m)^[ \t]*secret[ \t]*:.*$')) {
        $raw = [regex]::Replace($raw, '(?m)^[ \t]*secret[ \t]*:.*$', 'secret: ""')
    } else {
        $raw = [regex]::Replace($raw, '(?m)^(external-controller[ \t]*:.*)$', '$1' + "`r`n" + 'secret: ""', 1)
    }

    if ([regex]::IsMatch($raw, '(?m)^[ \t]*external-ui[ \t]*:.*$')) {
        $raw = [regex]::Replace($raw, '(?m)^[ \t]*external-ui[ \t]*:.*$', 'external-ui: "./ui"')
    } else {
        $raw += "`r`nexternal-ui: ""./ui""`r`n"
    }

    $raw = [regex]::Replace($raw, '(?m)^[ \t]*external-ui-url[ \t]*:.*$', '# external-ui-url disabled')
    Write-Utf8NoBom $config $raw
}

Write-Host ""
Write-Host "Effective controller settings:" -ForegroundColor Cyan
Get-Content $config | Where-Object {
    $_ -match '^[ \t]*(external-controller|secret|external-ui)[ \t]*:'
} | ForEach-Object {
    Write-Host ("  " + $_)
}
