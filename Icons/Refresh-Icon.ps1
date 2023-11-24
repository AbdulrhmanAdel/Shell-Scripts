$directory = $args[0];
# $refreshChilds = Read-Host "Do You Want To refresh Childs Defualt [Y]?";
$refreshChilds = "";

function RefreshIcon($folderpath) {
    Write-Output "Handling $folderpath";
    $desktopFilePath = "$directory/desktop.ini";
    if (-not (Test-Path -LiteralPath $desktopFilePath)) {
        return;
    }
    
    $fileContent = Get-Content -LiteralPath $desktopFilePath -Force;
    Remove-Item -LiteralPath $desktopFilePath -Force;
    
    
    $newDesktopFile = New-Item -Path $desktopFilePath -Force;
    $newDesktopFile.Attributes += 'Hidden';
    $newDesktopFile.Attributes += 'System';
    
    Set-Content -LiteralPath $desktopFilePath -Value $fileContent -Force;
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



