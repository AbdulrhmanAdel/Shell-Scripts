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
timeout.exe 15;