[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]$file
)

return Is-Audio.ps1 $file -or `
    Is-Video.ps1 $file;
