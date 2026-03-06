[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$basePath = Split-Path (Resolve-Path $Files[0]) -Parent
$archiveName = (Split-Path $basePath -Leaf) + ".7z"
$archivePath = Join-Path $basePath $archiveName

$arguments = @(
    "a"
    """$archivePath"""
    "-t7z"
    "-mx=0"
    "-mmt=20"
    "-mmemuse=p80"
    "-xr!node_modules"
)

$arguments += $Files | ForEach-Object { """$_""" }

$process = Start-Process 7z -ArgumentList $arguments -Wait -PassThru -NoNewWindow

if ($process.ExitCode -eq 0) {
    Write-Host "Archive created successfully: $archivePath" -ForegroundColor Green
}
else {
    Write-Host "7-Zip failed with exit code $($process.ExitCode)." -ForegroundColor Red
}

Read-Host "Press Any Key To Exit."
