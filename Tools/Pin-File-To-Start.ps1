$filePath = $args[0];

$fileInfo = Get-Item -LiteralPath $filePath;
$shortcutName = $fileInfo.Name.Replace($fileInfo.Extension, ".lnk");
$startmenuPath = "$($env:APPDATA)\Microsoft\Windows\Start Menu\Programs";

if ($fileInfo.Extension -in (".bat", ".ps1")) {
    $startmenuPath += "\Scripts";
}

if (!(Test-Path -LiteralPath $startmenuPath)) {
    New-Item -Path $startmenuPath -ItemType Directory -Force;
}

$ShortcutPath = "$startmenuPath\$shortcutName";
if (Test-Path -LiteralPath $ShortcutPath) {
    Remove-Item -LiteralPath $ShortcutPath;
}
$WshShell = New-Object -comObject "WScript.Shell";
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $filePath;
$Shortcut.Save();