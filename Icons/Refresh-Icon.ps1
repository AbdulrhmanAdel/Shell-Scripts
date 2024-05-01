$directory = $args[0];
& Parse-Args.ps1 $args;

if (!$directory) {
    $directory = Read-Host "Please enter directory path?";
}

function RefreshIcon($folderpath) {
    $directorInfo = Get-Item -LiteralPath $folderpath;
    $desktopFilePath = "$($directorInfo.FullName)\desktop.ini"; ;
    $desktopContent = Get-Content -LiteralPath $desktopFilePath;
    Remove-Item -LiteralPath "$($directorInfo.FullName)\desktop.ini" -Force;
    if ($directorInfo.Attributes.HasFlag([System.IO.FileAttributes]::System)) {
        $directorInfo.Attributes += 'System';
        Start-Sleep -Seconds 3;
    }

    Set-Content -LiteralPath $desktopFilePath $desktopContent;
    $desktopFileInfo = Get-item -LiteralPath $desktopFilePath -Force;
    $desktopFileInfo.Attributes += 'Hidden';
    $desktopFileInfo.Attributes += 'System';
    $directorInfo.Attributes += 'System';
}

if ($refreshChilds) {
    Get-ChildItem -LiteralPath $directory | ForEach-Object {
        if ($_.Attributes.HasFlag([System.IO.FileAttributes]::Directory)) {
            RefreshIcon -folderpath $_.FullName;
        }
    }
}
else {
    RefreshIcon -folderpath $directory;
}



