[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Path,
    [ValidateSet("Video", "Audio", "Text")]
    [string]$Type
)

$tracks = (& mediaInfo --Output=JSON "$Path" | ConvertFrom-Json).media.track;
if ($Type) {
    return @($tracks | Where-Object { $_.'@type' -eq $Type });
}

return $tracks;
