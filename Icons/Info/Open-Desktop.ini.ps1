$folderPath = $args[0];
if (-not (Test-Path -LiteralPath $folderPath)) {
    Exit;
}

$deskTopAndIco = Get-ChildItem -LiteralPath $folderPath -Include "desktop.ini" -Force;
$deskTopAndIco | ForEach-Object {
    Start-Process -FilePath $_.FullName
}
