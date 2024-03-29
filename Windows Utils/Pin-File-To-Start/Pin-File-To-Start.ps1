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
timeout.exe 10;
# $appName = $fileInfo.Name.Replace($fileInfo.Extension, "");
# $apps = Get-StartApps | Where-Object { $_.Name -eq $appName } ;

# Export-StartLayout -Path "C:\Temp\StartMenuLayout.xml";
# Write-Host "H"
# $shell = New-Object -ComObject "Shell.Application"
# $folder = $shell.Namespace($startmenuPath);
# $item = $folder.Parsename($shortcutName);
# $verb = $item.Verbs() | Where-Object { $_.Name -eq '&Pin to Start' }
# $verbs = $item.Verbs();

# foreach ($currentItemName in $verbs) {
#     $name = $currentItemName.Name;
#     $app = $currentItemName.Application;
#     $Parent = $currentItemName.Parent;
# }

# Write-Host $verbs;
# if ($verb) {
#     $item.InvokeVerb($verb);
#     $item.InvokeVerbEx($verb);
#     $verb.DoIt();
    
# }
# $fileAsExe = $fileAsExe.Replace(".exe", $fileInfo.Extension);
# Rename-Item `
#     -LiteralPath "$($fileInfo.FullName.Replace($fileInfo.Extension, ".exe"))" `
#     -NewName $fileAsExe;