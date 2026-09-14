param (
    [PSObject]$DownloadRequestArgs,
    [string]$DownloadPath = "$(Get-TempScriptPath.ps1)/Subtitle-Downloader/$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
)

if (!(Test-Path -LiteralPath $DownloadPath)) {
    New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null;
}

$DownloadFileName = Get-Date -Format "yyyy-MM-dd-HH-mm-ss";
$DownloadFilePath = "$DownloadPath\$DownloadFileName"
Invoke-WebRequest @DownloadRequestArgs -OutFile $DownloadFilePath;
return $DownloadFilePath;
