[CmdletBinding()]
param (
    $AppInfo,
    $Downloader,
    $Cleaner,
    $Installer
)

function ExecuteScript {
    param (
        $Item,
        $Path,
        $AdditionalArgs = @{}
    )

    $finalArgs = $AdditionalArgs + $Item.Args;
    return & "$PSScriptRoot\$Path\$($Item.Name)" @finalArgs;
}

$AppInfoDetails = ExecuteScript -Path "Details" -Item $AppInfo  @currentArgs;
$downloaderArtifacts = ExecuteScript -Path "Downloaders" -Item $Downloader @currentArgs;
if (!$downloaderArtifacts.HasNewVersion) {
    Write-Host "No new version found for $($AppInfoDetails.Name). Skipping update.";
    return;
}

$cleanerArtifacts = ExecuteScript -Path "Cleaners" -Item $Cleaner  @currentArgs;
if (!$cleanerArtifacts.Success) {
    Write-Host "Failed to clean old files for $($AppInfoDetails.Name). Aborting update.";
    return;
}

$Installer = ExecuteScript -Path "Installers" -Item $Installer -AdditionalArgs @{
    Path = $downloaderArtifacts.DownloadPath
}

