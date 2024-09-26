[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]$file
)

return $file -match "\.(mp3|m4a|opus|aac)$";