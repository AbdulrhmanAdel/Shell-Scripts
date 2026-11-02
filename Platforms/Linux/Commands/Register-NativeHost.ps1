[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$ExtensionId,
    [Parameter(Mandatory = $true)][string]$ScriptPath,
    [Parameter(Mandatory = $true)][string]$JsonPath,
    [Parameter()][string]$Description = "Native Host for $ExtensionId"
)

$parent = Split-Path $JsonPath;
$fullScriptPath = [IO.Path]::GetFullPath(($ScriptPath -replace '\\', '/'), $parent);
$launcher = Join-Path $parent "$Name.sh";
Set-Content -LiteralPath $launcher -Value "#!/bin/sh`nexec `"$((Get-Process -Id $PID).Path)`" -NoProfile -File `"$fullScriptPath`"";
& chmod +x $launcher;

$manifest = @{
    name            = $Name
    description     = $Description
    path            = $launcher
    type            = "stdio"
    allowed_origins = @("chrome-extension://$ExtensionId/")
} | ConvertTo-Json -Depth 100 -Compress;

@('google-chrome', 'chromium', 'BraveSoftware/Brave-Browser', 'microsoft-edge', 'vivaldi') | ForEach-Object {
    $config = Join-Path $HOME ".config/$_";
    if (Test-Path -LiteralPath $config) {
        $hosts = Join-Path $config 'NativeMessagingHosts';
        New-Item -ItemType Directory -Force $hosts | Out-Null;
        Set-Content -LiteralPath (Join-Path $hosts "$Name.json") -Value $manifest;
        Write-Host "Registered $Name for $_" -ForegroundColor Green;
    }
}
Timeout.ps1 15;
