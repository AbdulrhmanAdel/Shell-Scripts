[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Path,
    [Parameter(Mandatory)]
    [string]$Destination
)

& "$PSScriptRoot\_Copy.ps1" -Source $Path -Destination $Destination;