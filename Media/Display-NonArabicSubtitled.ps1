[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files,
    [switch]
    $CheckExternalSubtitles
)

$Files | Where-Object { Is-Video.ps1 -file $_ } | ForEach-Object {
    if (Has-SoftSubbedArabic.ps1 -Path $_) { return; }
    Write-Host $_ -ForegroundColor Green;
    Write-Host "";
}