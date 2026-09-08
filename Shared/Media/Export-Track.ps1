[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [System.IO.FileInfo]$FileInfo,
    [Parameter(Mandatory)]
    [int]$Index,
    [Parameter(Mandatory)]
    [string]$OutputPath
)

& ffmpeg "-y" "-v" "error" `
    "-stats" `
    "-i" "$($FileInfo.FullName)" `
    "-map" "0:$Index" `
    "-c" "copy" `
    "$OutputPath";

return $OutputPath;
