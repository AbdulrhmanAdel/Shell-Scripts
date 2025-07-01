[CmdletBinding()]
param (
    [string]
    [Alias("Target")]
    $SymbolLinkPath,
    [Parameter(Mandatory)]
    [string]
    [Alias("Source")]
    $LinkToPath,
    [bool]
    $NoReplace = $false
)

Write-Host 
if ($null -eq $SymbolLinkPath -or $SymbolLinkPath -eq "") {
    $SymbolLinkPath = Folder-Picker.ps1 -InitialDirectory ([System.IO.Path]::GetDirectoryName($LinkToPath)) -Required;
}

if ($LinkToPath.StartsWith("c") -or $SymbolLinkPath.StartsWith("c")) {
    Run-AsAdmin.ps1 -Arguments @(
        "-LinkToPath", $LinkToPath,
        "-SymbolLinkPath", $SymbolLinkPath,
        "-NoReplace", $NoReplace
    );
}

$isSourceFile = (Test-Path -LiteralPath $LinkToPath) `
    -and (Get-Item -LiteralPath $LinkToPath) -is [System.IO.FileInfo];
$isTargetFile = (Test-Path -LiteralPath $SymbolLinkPath) `
    -and (Get-Item -LiteralPath $SymbolLinkPath) -is [System.IO.FileInfo];
if ($isSourceFile -and !$isTargetFile) {
    $LinkToPathName = Split-Path -Path $LinkToPath -Leaf
    $SymbolLinkPath = "$SymbolLinkPath\$LinkToPathName";
}

if (!$NoReplace -and (Test-Path -LiteralPath $SymbolLinkPath)) {
    Remove-Item -LiteralPath $SymbolLinkPath -Force -Recurse;
}

New-Item `
    -Path $SymbolLinkPath `
    -Target $LinkToPath `
    -ItemType SymbolicLink;
    