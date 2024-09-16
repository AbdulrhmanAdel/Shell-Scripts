Write-Host "Set-Folder-Icon ARGS $($args)" -ForegroundColor DarkMagenta;

function AutoHandleIcon {
    $replaceText = "\[(FitGirl|Dodi).*\]|-.*Edition";
    $name = $directory.Name -replace $replaceText, "";
    $url = [System.Web.HttpUtility]::UrlEncode($directory.FullName);
    $isGame = $directory.FullName.Contains("Game");
    Start-Process "https://www.google.com/search?tbm=isch&q=$($name) $($isGame ? 'Game' : '') PNG Icon&path=$url";
}

function DonwloadImage {
    param (
        $imageUrl
    )
    
    Write-Host "Getting Image From " -NoNewline;
    Write-Host $imageUrl -ForegroundColor Red;
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
    $imageSourceType ??= & Options-Selector.ps1 @("FromBrowser (Auto)", "FromBrowser", "FromLink", "FromPath") -title "Select Icon Source" --mustSelectOne;
    switch ($imageSourceType) {
        "FromBrowser (Auto)" {
            AutoHandleIcon
            return DonwloadImage -imageUrl (Read-Host "If Auto Failed, Please Enter Icon Url Manually");
        }
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
. Parse-Args.ps1 $args;
$directory = Get-Item -LiteralPath $directoryPath -Force;
$iconPath = "$($directory.FullName)\$($directory.Name).ico";
$folderHasIcon = Test-Path -LiteralPath $iconPath;
if (!$folderHasIcon) {
    if (!$imagePath) {
        $imagePath = GetIamgePath
    }

    & "$($PSScriptRoot)/Utils/Convert-Png-To-Ico.ps1" -imagePath """$imagePath""" -saveFilePath """$iconPath""";
}
else {
    $overwrite = & Prompt.ps1 -Title "Icon Already Exists" -Message "Folder Already has icon. do you want to refresh it (Y) Get new one (N)?";
    if (!$overwrite) {
        if (!$imagePath) {
            $imagePath = GetIamgePath
        }
        & "$($PSScriptRoot)/Utils/Convert-Png-To-Ico.ps1" -imagePath """$imagePath""" -saveFilePath """$iconPath""";    
    }
}

# Hide the Icon
$iconFile = Get-Item -LiteralPath $iconPath -Force;
attrib.exe +h +s +r "$iconFile";

& "$PSScriptRoot/Set-Icon.ps1" $directory.FullName "./$($iconFile.Name)";
Write-Host "DONE Image Converted Successfully" -ForegroundColor Green;
# if ($noTimeout) {
#     EXIT;
# }

timeout.exe 10;