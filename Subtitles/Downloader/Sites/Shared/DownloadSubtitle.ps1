param (
    [Object]$Subtitle,
    [PSObject]$DownloadRequestArgs,
    [string]$DownloadPath = "$(Get-TempScriptPath)/Subtitle-Downloader/$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
)

if (!(Test-Path -LiteralPath $DownloadPath)) {
    New-Item -Path $DownloadPath -ItemType Directory -Force;
}

$DownloadFilePath = "$DownloadPath\$DownloadFileName"
$DownloadFileName = $Subtitle.FileName ?? (Get-Date -UFormat "%Y%m%d%H%M%S");
$DownloadPath = Invoke-WebRequest @DownloadRequestArgs -OutFile $DownloadFilePath;
if (-not (Test-Path -LiteralPath $DownloadPath)) {
    Write-Error "Failed to download subtitle to path: $DownloadPath"
    exit 1
}




