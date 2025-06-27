[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 1)]
    [string]
    $Source,
    [string]
    $Target,
    [switch]
    $NoReplace
)

Write-Host 
if ($Target -eq $null -or $Target -eq "") {
    $Target = Folder-Picker.ps1 -InitialDirectory ([System.IO.Path]::GetDirectoryName($Source)) -Required;
}


if ($Source.StartsWith("c") -or $Target.StartsWith("c")) {
    Run-AsAdmin.ps1 -Arguments @(
        "-Source", $Source,
        "-Target", $Target,
        "-NoReplace", $NoReplace
    );
}



$isSourceFile = (Get-Item -LiteralPath $Source) -is [System.IO.FileInfo];
$isTargetFile = (Get-Item -LiteralPath $Target) -is [System.IO.FileInfo];
if ($isSourceFile -and !$isTargetFile) {
    $SourceName = Split-Path -Path $Source -Leaf
    $Target = "$Target\$SourceName";
}

if (!$NoReplace -and (Test-Path -LiteralPath $Target)) {
    Remove-Item -LiteralPath $Target -Force -Recurse;
}

New-Item `
    -Path $Target `
    -Target $Source `
    -ItemType SymbolicLink;
    