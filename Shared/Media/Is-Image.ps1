[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]$file
)

return $file -match "\.(jpg|jpeg|png|gif|bmp|heic|dng)$";
