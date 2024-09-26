[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]$file
)

return $file -match "\.(ass|srt|sub)$";