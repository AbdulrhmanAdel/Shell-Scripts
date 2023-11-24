Write-Output $args;
$folderPath = $args[0];
$removeIcon = $args[1];

if (!$folderPath) {
    $folderPath = Read-Host "Please Enter Folder Path";
}

$desktopPathFile = "$folderPath\desktop.ini";

if ($removeIcon) {
    Remove-Item -LiteralPath $desktopPathFile -Force;
}
