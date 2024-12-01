[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 1)]
    [string]
    $DriveName
)
Write-Host "Getting Drives Info." -ForegroundColor Green;
$drives = Get-WmiObject -Class Win32_LogicalDisk 
return $drives | Where-Object { $_.VolumeName -eq $DriveName };
