# ==================================================================
# Update public RPC URL across MetaMask artifacts (HTML + JSON)
# Usage:
#   .\scripts\update-public-rpc-in-artifacts.ps1 -RpcUrl "https://rpc.unykorn.org"
#   .\scripts\update-public-rpc-in-artifacts.ps1 -RpcUrl "https://<your-quick-tunnel>.trycloudflare.com"
# ==================================================================
param(
    [Parameter(Mandatory=$true)]
    [string]$RpcUrl
)

$ErrorActionPreference = 'Stop'

function Update-File {
    param(
        [string]$Path,
        [ScriptBlock]$Updater
    )
    if (-not (Test-Path $Path)) {
        Write-Host "Skipping (not found): $Path" -ForegroundColor Yellow
        return
    }
    $orig = Get-Content -Raw -Path $Path -ErrorAction Stop
    $updated = & $Updater $orig
    if ($updated -ne $orig) {
        Copy-Item -Path $Path -Destination "$Path.bak" -Force
        Set-Content -Path $Path -Value $updated -Encoding UTF8
        Write-Host "Updated: $Path (backup saved as .bak)" -ForegroundColor Green
    } else {
        Write-Host "No changes needed: $Path" -ForegroundColor Cyan
    }
}

# Basic validation
if ($RpcUrl -notmatch '^https?://') {
    Write-Host "ERROR: RpcUrl must start with http:// or https://" -ForegroundColor Red
    exit 1
}

# 1) Update metamask-setup.html (both display code block and NETWORK_CONFIG)
$mmHtml = Join-Path $PSScriptRoot '..' 'metamask-setup.html'
Update-File -Path $mmHtml -Updater {
    param($text)
    $t = $text
    # Replace the displayed URL in info box code element
    $t = [regex]::Replace($t, '(?<=<code>)https?://[^<]+(?=</code>)', [regex]::Escape($RpcUrl))
    # Replace rpcUrls array first element in NETWORK_CONFIG
    $t = [regex]::Replace($t, 'rpcUrls:\s*\[[^\]]*\]', "rpcUrls: ['$RpcUrl','http://127.0.0.1:8555']")
    return $t
}

# 2) Update MetaMask_Network_7777.json (first rpcUrls value)
$mmJson = Join-Path $PSScriptRoot '..' 'MetaMask_Network_7777.json'
Update-File -Path $mmJson -Updater {
    param($text)
    $t = $text
    $t = [regex]::Replace($t, '"rpcUrls"\s*:\s*\[[^\]]*\]', '"rpcUrls": ["' + [regex]::Escape($RpcUrl) + '", "http://127.0.0.1:8555"]')
    return $t
}

Write-Host "\nDone. If you updated to a quick tunnel URL, remember it will change on restart." -ForegroundColor Yellow
