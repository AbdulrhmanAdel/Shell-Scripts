function RemoveIcon {
    param (
        [Parameter()]
        [string]
        $Folderpath
    )

    $folder = Get-Item -LiteralPath $Folderpath;
    if ($folder.Attributes.HasFlag([System.IO.FileAttributes]::System)) {
        $folder.Attributes -= [System.IO.FileAttributes]::System;
    }
    if ($folder.Attributes.HasFlag([System.IO.FileAttributes]::ReadOnly)) {
        $folder.Attributes -= [System.IO.FileAttributes]::ReadOnly;
    }
    
    $iconAndDesktop = Get-ChildItem -LiteralPath $Folderpath -Include "desktop.ini", "*.ico" -Force;
    if ($iconAndDesktop.Length -ne 2) {
        return;
    }

    $iconAndDesktop | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Force
    }
}


RemoveIcon -Folderpath $args[0];