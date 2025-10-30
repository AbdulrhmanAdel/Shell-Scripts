[CmdletBinding()]
param (
    $CurrentVersion,
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

    if (!$Item -or !$Item.Name) {
        Write-Host "[WARN] No $Item for $Path specified. Skipping." -ForegroundColor DarkGray
        return $null;
    }

    $finalArgs = $AdditionalArgs + $Item.Args;
    return & "$PSScriptRoot\$Path\$($Item.Name)" @finalArgs;
}

$CurrentVersionDetails = $CurrentVersion.Name -eq "Direct" ? $CurrentVersion.Args : (ExecuteScript -Path "Details" -Item $CurrentVersion);
$downloaderArtifacts = ExecuteScript -Path "Downloaders" -AdditionalArgs @{
    CurrentVersion = ($CurrentVersionDetails)?.Version
} -Item $Downloader;

if (!$downloaderArtifacts.HasNewVersion) {
    Write-Host "No new version found for $($CurrentVersionDetails.Name) Latest Version $($downloaderArtifacts.LatestVersion). Skipping update.";
    timeout.exe 10;
    return @{
        Success = $false
    }
}

$cleanerArtifacts = ExecuteScript -Path "Cleaners" -Item $Cleaner ;
if (!$cleanerArtifacts.Success) {
    Write-Host "Failed to clean old files for $($CurrentVersionDetails.Name). Aborting update.";
    return @{
        Success = $false
    }
}

$Installer = ExecuteScript -Path "Installers" -Item $Installer -AdditionalArgs @{
    Path = $downloaderArtifacts.DownloadPath
}

return @{
    Success = $true
}
