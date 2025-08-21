[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Extension
)

if ($Extension -and !$Extension.StartsWith('.')) {
    $Extension = ".$Extension"
}

return "$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')$($Extension)";