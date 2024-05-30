$filePath = $args[0];

if (!(Test-Path -LiteralPath $filePath)) {
    EXIT;
}

Get-FileHash -LiteralPath $filePath;

Read-Host "PRESS ANY KEY TO EXIT."
timeout.exe 15;