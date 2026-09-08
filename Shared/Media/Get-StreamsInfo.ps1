[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Path,
    [string]$Entries = "stream=index,codec_name,codec_type,codec_long_name:stream_tags=language"
)

return (& ffprobe -v error -print_format json -show_entries $Entries "$Path" | ConvertFrom-Json).streams;
