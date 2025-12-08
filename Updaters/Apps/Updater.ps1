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
Write-Host "Starting update process for $($CurrentVersion.Name)" -ForegroundColor Green;
Write-Host "===================== Download =====================" -ForegroundColor Green;
$downloaderArtifacts = ExecuteScript -Path "Downloaders" -AdditionalArgs @{
    CurrentVersion = ($CurrentVersionDetails)?.Version
} -Item $Downloader;
Write-Host "===================== End Download =====================" -ForegroundColor Green;

if (!$downloaderArtifacts.HasNewVersion) {
    Write-Host "No new version found for $($CurrentVersionDetails.Name) Latest Version $($downloaderArtifacts.LatestVersion). Skipping update.";
    timeout.exe 10;
    return @{
        Success = $false
    }
}
Write-Host "";
Write-Host "===================== Clean Old Version =====================" -ForegroundColor Gray;
$cleanerArtifacts = ExecuteScript -Path "Cleaners" -Item $Cleaner ;
if (!$cleanerArtifacts.Success) {
    Write-Host "Failed to clean old files for $($CurrentVersionDetails.Name). Aborting update.";
    return @{
        Success = $false
    }
}
Write-Host "===================== End Clean Old Version =====================" -ForegroundColor Gray;

$Installer = ExecuteScript -Path "Installers" -Item $Installer -AdditionalArgs @{
    Path = $downloaderArtifacts.DownloadPath
}

return @{
    Success = $true
}
