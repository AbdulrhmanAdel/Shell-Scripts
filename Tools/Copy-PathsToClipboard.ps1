[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths
)

$data = $Paths | ForEach-Object {
    $new = $_ -replace "\\", "\\";
    return """\""$new\"""""
}

# Write-Host $data;
Set-Clipboard -Value "$($data -join ", ")"
