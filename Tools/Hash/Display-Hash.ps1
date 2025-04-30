[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths
)

$Paths | ForEach-Object {
    $filePath = $_;
    Write-Host "==========================" -ForegroundColor Green;
    Write-Host "File: $($hash.Path)";
    $hash = Get-FileHash -LiteralPath $filePath;
    Write-Host "Hash: $($hash.Hash)";
    Write-Host "==========================" -ForegroundColor Green;
    Write-Host "";
}

Read-Host "PRESS ANY KEY TO EXIT."
