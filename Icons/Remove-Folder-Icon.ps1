Write-Output $args;
$folderPath = $args[0];
if (-not (Test-Path -LiteralPath $folderPath)) {
    Exit;
}

$deskTopAndIco = Get-ChildItem -LiteralPath -Include "desktop.ini", "*.ico" -Force;
$deskTopAndIco | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Force;
}

