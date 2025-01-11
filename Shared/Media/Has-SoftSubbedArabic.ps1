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

$streamsInfo = & ffprobe -v error -print_format json -show_entries `
    "stream=index,codec_name,codec_type,codec_long_name:stream_tags=language" `
    "$Path" | ConvertFrom-Json;

return @($streamsInfo.streams | Where-Object { $_.codec_name -match "srt|ass" }) | Where-Object {
    $_.tags.language -in @("ara", "ar")
};