[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths
)

$Paths | ForEach-Object {
    $filePath = $_;
    Write-Host "==========================" -ForegroundColor Green;
    Write-Host "File: " -ForegroundColor Green -NoNewline;
    Write-Host (Split-Path -Path $filePath -Leaf);
    $hash = Get-FileHash -LiteralPath $filePath;
    Write-Host "$($hash.Algorithm): " -ForegroundColor Green -NoNewline;
    Write-Host $hash.Hash;
    Set-Clipboard -Value $hash.Hash;
    Write-Host "==========================" -ForegroundColor Green;
    Write-Host "";
}

Read-Host "PRESS ANY KEY TO EXIT."
