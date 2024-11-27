[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 1)]
    [string]
    $Source,
    [Parameter(Mandatory, Position = 2)]
    [string]
    $Target,
    [switch]
    $NoReplace
)

if ($Source.StartsWith("c") -or $Target.StartsWith("c")) {
    Run-AsAdmin.ps1;
}


if (!$NoReplace -and (Test-Path -LiteralPath $Target)) {
    Remove-Item -LiteralPath $Target -Force -Recurse;
}

New-Item `
    -Path $Target `
    -Target $Source `
    -ItemType SymbolicLink;
    