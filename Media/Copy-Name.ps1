[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]
    $Path
)

$details = Get-ShowDetails.ps1 -Path $Path -OnlyBasicInfo;
$details.Keys | ForEach-Object {
    Write-Host $_ -ForegroundColor Green -NoNewline;
    Write-Host ": $($details[$_])";
}
Set-Clipboard -Value $details.Title;
timeout.exe 15;