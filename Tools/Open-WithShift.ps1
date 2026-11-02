[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$Files | ForEach-Object {
    Start-Process pwsh.exe -ArgumentList @(
        "-File"
        """$_"""
        "-Shift"
    )
}

Write-Host $Files;
Timeout.ps1 15;