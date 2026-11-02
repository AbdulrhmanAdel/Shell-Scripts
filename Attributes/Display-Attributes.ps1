$itemPath = $args[0];

$item = Get-Item -LiteralPath $itemPath;

Write-Host $itemPath -ForegroundColor Green
if ($item) {
    Write-Host $item.Attributes -ForegroundColor Green;
}

Timeout.ps1 15;