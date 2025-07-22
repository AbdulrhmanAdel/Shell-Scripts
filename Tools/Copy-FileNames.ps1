[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths
)

$data = $Paths | ForEach-Object {
    return Split-Path -Path $_ -Leaf;
}

Set-Clipboard -Value "$($data -join ", ")"
