[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Project,
    [Parameter(Mandatory)]
    [string]$ReleasePattern,
    [string]$VersionPattern,
    $CurrentVersion
)

# Fetch RSS feed
$rssUrl = "https://sourceforge.net/projects/$Project/rss"
$data = Invoke-WebRequest -Uri $rssUrl -UseBasicParsing
[xml]$xml = $data.Content
$items = $xml.rss.channel.item

# Find the latest item matching the title
$latest = $items | Where-Object { $_.link -match $ReleasePattern } | Select-Object -First 1
if (-not $latest) {
    Write-Error "No release found matching '$ReleasePattern' for project '$Project'."
    return
}

$fullName = $latest.title.InnerText;
$fileName = ($fullName -split '/')[-1];
$downloadLink = "https://netcologne.dl.sourceforge.net/project/$($Project)$($fullName)?viasf=1"
$downloadPath = & "$PSScriptRoot\_Downloader.ps1" `
    -Url $downloadLink `
    -FileName $fileName;

return @{
    HasNewVersion = $true
    DownloadPath  = $downloadPath
}