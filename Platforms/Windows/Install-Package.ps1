[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]
    $Path
)

Run-AsAdmin.ps1 -Arguments @(
    "-Path", """$Path"""
);

Add-AppPackage $Path;

timeout.exe 10;