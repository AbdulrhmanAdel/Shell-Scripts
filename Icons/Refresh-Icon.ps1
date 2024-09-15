function RefreshIcon($directorInfo) {
    $desktopFilePath = "$($directorInfo.FullName)\desktop.ini";
    $desktopContent = Get-Content -LiteralPath $desktopFilePath;
    Remove-Item -LiteralPath "$($directorInfo.FullName)\desktop.ini" -Force;
    attrib.exe "+s" "+r" "$($directorInfo.FullName)";
    Set-Content -LiteralPath $desktopFilePath $desktopContent;
    attrib.exe "+s" "+r" "$($desktopFilePath)";
}

$directory = $args[0];
if (!$directory) {
    $directory = Read-Host "Please enter directory path?";
}

$desktops = Get-ChildItem -LiteralPath $directory `
    -Filter "desktop.ini" `
    -Recurse -Force;

$desktops | ForEach-Object {
    RefreshIcon -directorInfo $_.Directory
}



