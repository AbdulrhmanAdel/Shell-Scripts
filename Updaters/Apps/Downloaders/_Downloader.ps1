[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Url,
    [object]
    $FileName,
    # Cache per version, many apps reuse one file name (e.g. nomacs-portable-win.zip) for every release
    [string]
    $Version,
    # When known (GitHub gives it), a cached file of another size is re-downloaded
    [long]
    $ExpectedSize = 0,
    [string]
    $UserAgent
)

$FileName ??= Random-FileName.ps1;
$parentPath = "$(Get-TempScriptPath.ps1)\App_Updaters"
if ($Version) {
    $parentPath = "$parentPath\$($Version -replace '[\\/:*?"<>|\s]', '_')";
}
$OutPath = "$parentPath\$FileName";

$cached = Test-Path -LiteralPath $OutPath;
if ($cached -and $ExpectedSize -gt 0 -and (Get-Item -LiteralPath $OutPath).Length -ne $ExpectedSize) {
    Write-Host "[INFO] Cached file has the wrong size, downloading again." -ForegroundColor DarkGray
    $cached = $false;
}

if ($cached) {
    Write-Host "[INFO] File already exists at $OutPath. Skipping download." -ForegroundColor DarkGray
    return $OutPath;
}

New-Item -Path $parentPath -ItemType Directory -Force | Out-Null;
# Download to .part first so an interrupted download is never mistaken for a finished one
$partPath = "$OutPath.part";
$requestArgs = @{ Uri = $Url; OutFile = $partPath };
if ($UserAgent) {
    $requestArgs.UserAgent = $UserAgent;
}
try {
    Invoke-WebRequest @requestArgs -ErrorAction Stop;
    Move-Item -LiteralPath $partPath -Destination $OutPath -Force;
}
catch {
    Remove-Item -LiteralPath $partPath -Force -ErrorAction SilentlyContinue;
    Write-Host "[ERROR] Download failed: $Url ($($_.Exception.Message))" -ForegroundColor Red
    return $null;
}

return $OutPath;
