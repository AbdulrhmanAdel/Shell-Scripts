param (
    [Object]$Subtitle,
    [PSObject]$DownloadRequestArgs,
    [string]$DownloadPath = "$(Get-TempScriptPath)/Subtitle-Downloader/$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
)

if (!(Test-Path -LiteralPath $DownloadPath)) {
    New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null;
}

$DownloadFileName = ($Subtitle)?.FileName ?? (Get-Date -Format "yyyy-MM-dd-HH-mm-ss");
$DownloadFilePath = "$DownloadPath\$DownloadFileName"
$DownloadPath = Invoke-WebRequest @DownloadRequestArgs -OutFile $DownloadFilePath;
return $DownloadFilePath;

