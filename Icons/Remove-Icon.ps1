[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 1)]
    [string]
    $FolderPath
)

if (-not (Test-Path -LiteralPath $FolderPath)) {
    Exit;
}

$deskTopAndIco = Get-ChildItem -LiteralPath $FolderPath -Include "desktop.ini", "*.ico" -Force;
$deskTopAndIco | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Force;
}

& "$PSScriptRoot/Refresh-Icon.ps1" -FolderPath $FolderPath;