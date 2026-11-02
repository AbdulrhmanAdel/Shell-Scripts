[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path
)

$item = Get-Item -LiteralPath $Path;
return $item.ResolveLinkTarget($true).FullName ?? $item.FullName;
