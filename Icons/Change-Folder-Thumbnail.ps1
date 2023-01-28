Write-Output $args;
$folderPath = $args[0];
$removeIcon = $args[1];

if (!$folderPath) {
    $folderPath = Read-Host "Please Enter Folder Path";
}

$desktopPathFile = "$folderPath\desktop.ini";

if ($removeIcon) {
    Set-Content $desktopPathFile -Force -Value "";
}
else {
    $newIconPath = Get-ChildItem $folderPath -Force | Where-Object { $_ -like "*.ico*" };
    if (!$newIconPath) {
        $newIconPath = Read-Host "Please Enter Icon Path";
    }
    else {
        $newIconPath = $newIconPath[0].FullName;
    }

    Set-Content $desktopPathFile -Value "[.ShellClassInfo]
IconFile=folder.ico
IconIndex=0
ConfirmFileOp=0
IconResource=$newIconPath"
}
Read-Host "Please Enter Any key to exits";

