[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 1)]
    [string]
    $DriveName
)
Write-Host "Getting Drives Info." -ForegroundColor Green;
$devices = (& lsblk --json --bytes --list --output LABEL,MOUNTPOINT,SIZE,FSAVAIL | ConvertFrom-Json).blockdevices;
return $devices | Where-Object { $_.label -eq $DriveName } | ForEach-Object {
    [PSCustomObject]@{ VolumeName = $_.label; DeviceID = $_.mountpoint; Size = $_.size; FreeSpace = $_.fsavail }
};
