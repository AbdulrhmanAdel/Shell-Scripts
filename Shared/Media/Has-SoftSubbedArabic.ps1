[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path
)

if (!(Test-Path -LiteralPath $Path)) {
    Write-Error "File not found: $Path";
    return $false;
}

$streams = Get-StreamsInfo.ps1 -Path $Path;
return @($streams | Where-Object { $_.codec_name -match "srt|ass" }) | Where-Object {
    $_.tags.language -in @("ara", "ar")
};