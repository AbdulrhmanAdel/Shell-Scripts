[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path
)

return Get-ItemProperty -LiteralPath $Path;