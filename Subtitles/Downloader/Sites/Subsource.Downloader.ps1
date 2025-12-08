param(
    [psobject]$abstractSub,
    [string]$downloadPath,
    [string]$baseApiURL,
    [hashtable]$headers,
    [string]$siteDomain
)

# Example site-specific downloader for Subsource.
# It receives the abstract sub object produced by DownloadSubtitle.ps1 and must return a path to the downloaded archive file.

if (-not $abstractSub) { Write-Error "No abstract sub received"; exit 1 }

$id = $abstractSub.OriginalData.subtitleId
if (-not $id) {
    Write-Error "No subtitleId available on OriginalData"
    exit 1
}

$fn = ($abstractSub.ReleaseInfo -replace '[<>:\"/\\|?*]', ' ' -replace '  *', ' ').Trim()
if (-not (Test-Path -LiteralPath $downloadPath)) { New-Item -ItemType Directory -Path $downloadPath | Out-Null }
$out = Join-Path $downloadPath $fn

Invoke-WebRequest -Uri "$baseApiURL/subtitles/$id/download" -Headers $headers -OutFile $out

# Return the downloaded file path
Write-Output $out
