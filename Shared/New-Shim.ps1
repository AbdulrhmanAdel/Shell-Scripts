[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Name,
    [string] $Target
)

if (-not $Target) {
    $Target = & "$PSScriptRoot\Inputs\File-Picker.ps1" -Title "Select target for shim '$Name'" -Required
}
$Target = (Resolve-Path -LiteralPath $Target).Path

$hubsFile = "$PSScriptRoot\Modules\Shim\hubs.local.json"
$hubs = @()
if (Test-Path -LiteralPath $hubsFile) {
    $hubs = @(Get-Content -LiteralPath $hubsFile -Raw | ConvertFrom-Json)
}

$match = $hubs | Where-Object { $Target -like "$($_.Prefix)*" } | Sort-Object { $_.Prefix.Length } -Descending | Select-Object -First 1
if (-not $match) {
    throw "No hub configured for '$Target'. Add a { Prefix, Hub } entry to $hubsFile"
}
$hub = $match.Hub

$shimDir = "$PSScriptRoot\Modules\Shim"
$shimExe = "$shimDir\bin\shim.exe"

if (-not (Test-Path -LiteralPath $shimExe) -or (Get-Item "$shimDir\Program.cs").LastWriteTime -gt (Get-Item -LiteralPath $shimExe).LastWriteTime) {
    dotnet publish "$shimDir\Shim.csproj" -c Release -o "$shimDir\bin" | Out-Null
    if (-not (Test-Path -LiteralPath $shimExe)) {
        throw "Failed to build shim.exe"
    }
}

New-Item -Path $hub -ItemType Directory -Force | Out-Null
Copy-Item -LiteralPath $shimExe -Destination "$hub\$Name.exe" -Force
Set-Content -Path "$hub\$Name.shim" -Value $Target -Encoding ascii -NoNewline

Write-Host "$Name -> $Target (via $hub)" -ForegroundColor Green
