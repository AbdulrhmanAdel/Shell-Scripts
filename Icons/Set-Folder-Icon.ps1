Write-Host "Set-Folder-Icon ARGS $($args)" -ForegroundColor DarkMagenta;
function DonwloadImage {
    param (
        $imageUrl
    )
    
    $tempFilePath = "$($env:TEMP)\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').png";
    if (Test-Path -LiteralPath $tempFilePath) {
        if (-not (Read-Host "Do you want to Use Image From Cache?")) {
            return $tempFilePath;
        }

        Remove-Item -LiteralPath $tempFilePath -Force
    }

    $tempImage = New-Item "$tempFilePath"; 
    Invoke-WebRequest -UseBasicParsing -uri $imageUrl -outfile $tempFilePath;
    return $tempImage.FullName;
}

function GetIamgePath {
    $imageSourceType ??= & Options-Selector.ps1 @("FromBrowser", "FromLink", "FromPath") -title "Select Icon Source" --mustSelectOne;
    switch ($imageSourceType) {
        "FromBrowser" {
            Start-Process "https://www.google.com/search?tbm=isch&q=$($directory.Name) Icon";
            return DonwloadImage -imageUrl (Read-Host "Please Enter Icon Url");
        }
        "FromLink" { 
            $imageUrl = Read-Host "Please Enter Icon Url";
            return DonwloadImage -imageUrl $imageUrl;
        }
        "FromPath" { 
            return Read-Host "Please Enter Icon Path.";
        }
    }

}

function Hide {
    param (
        $fileInfo
    )
    
    if (!$fileInfo.Attributes.HasFlag([System.IO.FileAttributes]::Hidden)) {
        $fileInfo.Attributes += 'Hidden';
    }
    if (!$fileInfo.Attributes.HasFlag([System.IO.FileAttributes]::System)) {
        $fileInfo.Attributes += 'System';
    }
}


$directoryPath = $args[0]
& Parse-Args.ps1 $args;
if (!$imagePath) {
    $imagePath = GetIamgePath
}

$directory = Get-Item -LiteralPath $directoryPath -Force;
$iconPath = "$($directory.FullName)\$($directory.Name).ico";
& "$($PSScriptRoot)/Utils/Convert-Png-To-Ico.ps1" -imagePath """$imagePath""" -saveFilePath """$iconPath""";

# Hide the Icon
$iconFile = Get-Item -LiteralPath $iconPath -Force;
Hide -fileInfo $iconFile;

# Change Folder Icon
$desktopPathFile = "$directoryPath\desktop.ini";
$desktopFileContent = "[.ShellClassInfo]", "IconResource=.\$($directory.Name).ico,0";
Set-Content -LiteralPath $desktopPathFile -Value $desktopFileContent -Force -PassThru;
$desktopFileInfo = Get-Item -LiteralPath $desktopPathFile -Force;
Hide -fileInfo $desktopFileInfo;
Write-Host "DONE Image Converted Successfully" -ForegroundColor Green;

if (!$directory.Attributes.HasFlag([System.IO.FileAttributes]::System)) {
    $directory.Attributes += 'System';
}

if ($noTimeout) {
    EXIT;
}

timeout.exe 10;