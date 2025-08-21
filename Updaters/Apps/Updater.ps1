[CmdletBinding()]
param (
    $AppInfo,
    $Downloader,
    $Cleaner,
    $Installer
)

function Expand {
    param (
        $Dic
    )

    $sb = [System.Text.StringBuilder]::new()
    foreach ($key in $Dic.Keys) {
        [void]$sb.Append("-$($key) $($Dic[$key])")
    }
    return $sb.ToString()
}

$currentArgs = $AppInfo.Args;
$AppInfoDetails = & "$PSScriptRoot\Details\$($AppInfo.Name)"  @currentArgs;
$currentArgs = $Downloader.Args;
$downloaderArtifacts = & "$PSScriptRoot\Downloaders\$($Downloader.Name)"  @currentArgs;
$currentArgs = $Cleaner.Args;
$downloaderArtifacts = & "$PSScriptRoot\Cleaners\$($Cleaner.Name)"  @currentArgs;
$currentArgs = $Installer.Args;
$Installer = & "$PSScriptRoot\Installers\$($Installer.Name)" -Path $downloaderArtifacts.DownloadPath @currentArgs;

