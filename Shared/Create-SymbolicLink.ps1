[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 1)]
    [string]
    [Alias("Source")]
    $LinkToPath,
    [string]
    [Alias("Target")]
    $SymbolLinkPath,
    [switch]
    $NoReplace
)

Write-Host 
if ($SymbolLinkPath -eq $null -or $SymbolLinkPath -eq "") {
    $SymbolLinkPath = Folder-Picker.ps1 -InitialDirectory ([System.IO.Path]::GetDirectoryName($Source)) -Required;
}


if ($Source.StartsWith("c") -or $SymbolLinkPath.StartsWith("c")) {
    Run-AsAdmin.ps1 -Arguments @(
        "-Source", $Source,
        "-Target", $SymbolLinkPath,
        "-NoReplace", $NoReplace
    );
}



$isSourceFile = (Get-Item -LiteralPath $Source) -is [System.IO.FileInfo];
$isTargetFile = (Get-Item -LiteralPath $SymbolLinkPath) -is [System.IO.FileInfo];
if ($isSourceFile -and !$isTargetFile) {
    $SourceName = Split-Path -Path $Source -Leaf
    $SymbolLinkPath = "$SymbolLinkPath\$SourceName";
}

if (!$NoReplace -and (Test-Path -LiteralPath $SymbolLinkPath)) {
    Remove-Item -LiteralPath $SymbolLinkPath -Force -Recurse;
}

New-Item `
    -Path $SymbolLinkPath `
    -Target $Source `
    -ItemType SymbolicLink;
    