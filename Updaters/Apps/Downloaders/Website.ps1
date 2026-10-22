[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    $Url,
    $VersionPattern = "v",
    $VersionPatternName = "Version",
    # Regex for the download link on the page: its "Url" group, or the whole match. Without it only the version is detected
    $DownloadPattern,
    $CurrentVersion,
    [switch]
    $CheckOnly
)

$html = Invoke-WebRequest -Uri $Url;
if (-not ($html.Content -match $VersionPattern)) {
    return @{
        HasNewVersion = $false
        Message       = "Can't extract the version from $Url"
    }
}

$newVersion = $Matches[$VersionPatternName]
$HasNewVersion = & "$PSScriptRoot\_Version-Compare.ps1" -CurrentVersion $CurrentVersion -NewVersion $newVersion;
if (!$HasNewVersion) {
    Write-Host "No new version found. Current version ($CurrentVersion) is up to date.";
    return @{
        HasNewVersion = $false
        LatestVersion = $newVersion
    }
}

if ($CheckOnly -or !$DownloadPattern) {
    return @{
        HasNewVersion = $true
        LatestVersion = $newVersion
        Message       = $CheckOnly ? $null : "The Website downloader has no DownloadPattern, download $newVersion manually from $Url"
    }
}

if (-not ($html.Content -match $DownloadPattern)) {
    return @{
        HasNewVersion = $true
        LatestVersion = $newVersion
        Message       = "Can't find the download link of $newVersion on $Url"
    }
}

$downloadLink = $Matches.ContainsKey('Url') ? $Matches.Url : $Matches[0];
# Resolve relative URLs
if (-not $downloadLink.StartsWith('http')) {
    $downloadLink = [System.Uri]::new([System.Uri]$Url, $downloadLink).AbsoluteUri
}

$fileName = ([System.Uri]$downloadLink).Segments[-1]
$downloadPath = & "$PSScriptRoot\_Downloader.ps1" -Url $downloadLink -FileName $fileName -Version $newVersion;

return @{
    HasNewVersion = $true
    LatestVersion = $newVersion
    DownloadPath  = $downloadPath
}
