param (
    [switch]$Save
)

Import-Module "$PSScriptRoot\Aria2.psm1" -Force;
if ($Save) {
    Save-Aria2Settings;
    return;
}
Start-DownloadManager | Out-Null;
Open-AriaNg | Out-Null;
