[CmdletBinding()]
param (
    [string]
    [Alias("Target", "Path")]
    $SymbolLinkPath,
    [Parameter(Mandatory)]
    [string]
    [Alias("Source")]
    $LinkToPath,
    [bool]
    $NoReplace = $false
)

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

$targetPathInfo = Get-Item -LiteralPath $LinkToPath -ErrorAction SilentlyContinue;
if (!$targetPathInfo) {
    Write-Error "Can't Link to invalid path."
    Exit;
}

$symbolLinkPathInfo = Get-Item -LiteralPath $SymbolLinkPath -ErrorAction SilentlyContinue;
if (
    $SymbolLinkPathInfo `
        -and $symbolLinkPathInfo -is [System.IO.DirectoryInfo] `
        -and $targetPathInfo -is [System.IO.FileInfo]) {
    $SymbolLinkPath = "$SymbolLinkPath\$($targetPathInfo.Name)";                                           
}

if (!$NoReplace -and (Test-Path -LiteralPath $SymbolLinkPath)) {
    Remove-Item -LiteralPath $SymbolLinkPath -Force -Recurse;
}

New-Item `
    -Path $SymbolLinkPath `
    -Target $LinkToPath `
    -ItemType SymbolicLink;
    