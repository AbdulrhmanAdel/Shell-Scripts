[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Target,
    [Parameter(Mandatory)]
    [string]$Source
)

New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null;
