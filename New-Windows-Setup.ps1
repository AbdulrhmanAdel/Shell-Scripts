[CmdletBinding()]
param (
    [switch]
    $FirstRun
)

if ($FirstRun) {
    & "$PSScriptRoot/Add-Shared-To-Path.ps1";
    
    EXIT;
}

Run-AsAdmin.ps1;
$drives = Get-PSDrive -PSProvider FileSystem  | Foreach-Object { return $_.Name };
# regsion Programs

# endRegsion