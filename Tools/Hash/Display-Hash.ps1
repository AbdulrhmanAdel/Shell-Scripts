[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths
)

$Paths | ForEach-Object {
    $filePath = $_;
    Write-Host "==========================" -ForegroundColor Green;
    Write-Host "File: " -NoNewline;
    Write-Host $filePath -ForegroundColor Green;
    $hash = Get-FileHash -LiteralPath $filePath;
    Write-Host "$($hash.Algorithm): $($hash.Hash)";
    Set-Clipboard -Value $hash.Hash;
    Write-Host "==========================" -ForegroundColor Green;
    Write-Host "";
}

Read-Host "PRESS ANY KEY TO EXIT."
