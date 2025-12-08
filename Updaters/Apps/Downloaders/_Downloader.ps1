[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Url,
    [object]
    $FileName
)

$FileName ??= Random-FileName.ps1;
$parentPath = "$(Get-TempScriptPath)\App_Updaters"
$OutPath = "$parentPath\$FileName";
if (-not (Test-Path $OutPath)) {
    New-Item -Path $parentPath -ItemType Directory -Force | Out-Null;
    Invoke-WebRequest -Uri $Url -OutFile $OutPath;
}
else {
    Write-Host "[INFO] File already exists at $OutPath. Skipping download." -ForegroundColor DarkGray
}

return $OutPath;