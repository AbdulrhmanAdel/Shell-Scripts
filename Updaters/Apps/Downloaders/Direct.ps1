[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Url,
    [Parameter()]
    [object]
    $OutPath,
    [object]
    $AppName,
    $ArchiveType = "zip"
)
$AppName ??= Random-FileName.ps1;
$parentPath = "$($env:TEMP)\App_Updaters"
$OutPath ??= "$parentPath\$($AppName).$ArchiveType"
if (-not (Test-Path $OutPath)) {
    New-Item -Path $parentPath -ItemType Directory -Force | Out-Null;
    Invoke-WebRequest -Uri $Url -OutFile $OutPath;
}

return @{
    DownloadPath = $OutPath;
}