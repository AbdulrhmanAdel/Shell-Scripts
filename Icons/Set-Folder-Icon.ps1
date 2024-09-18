Write-Host "Set-Folder-Icon ARGS $($args)" -ForegroundColor DarkMagenta;

function OpenBrowser {
    param(
        [switch]
        $AppendPath
    )

    $iconWebsite = & Options-Selector.ps1 @("Google", "Yandex", "Deviantart") `
        -title "Select Icon Website" --mustSelectOne;
    $iconWebsite ??= "Deviantart";
    $replaceText = "\[(FitGirl|Dodi).*\]|-.*Edition";
    $name = $directory.Name -replace $replaceText, "";
    $isGame = $directory.FullName.Contains("Game");
    $query = "$($name) $($isGame ? 'Game' : '') Icon";
    if ($AppendPath) {
        $url = [System.Web.HttpUtility]::UrlEncode($directory.FullName);
        $query += "&path=$url"
    }

    $link = $null;
    switch ($iconWebsite) {
        "Google" { $link = "https://www.google.com/search?tbm=isch&q=$query"; break; }
        "Yandex" { $link = "https://yandex.com/images/search?ih=256&iw=256&isize=eq&itype=png&text=$query"; break; }
        "Deviantart" { $link = "https://www.deviantart.com/search?q=$query"; break; }
        Default { $link = "https://www.deviantart.com/search?q=$query"; }
    }
    Start-Process $link;
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
    Write-Host "Image Downloaded To $($tempImage.FullName)" -ForegroundColor Red;
    return $tempImage.FullName;
}


$imageSourceHandlers = @{
    "FromBrowser (Auto Set)" = {
        OpenBrowser -AppendPath;
        EXIT;
    }
    "FromBrowser"            = { 
        OpenBrowser;
        return DonwloadImage -imageUrl (Read-Host "Please Enter Icon Url"); 
    }
    "FromLink"               = { 
        $imageUrl = Read-Host "Please Enter Icon Url";
        return DonwloadImage -imageUrl $imageUrl; 
    }
    "FromPath"               = { return Read-Host "Please Enter Icon Path."; }
};

function GetIamgePath {
    $imageSource ??= & Options-Selector.ps1 $imageSourceHandlers.Keys -title "Select Icon Source" --mustSelectOne;
    $imageSourceHandlerFn = $imageSourceHandlers[$imageSource];
    if ($imageSourceHandlerFn) {
        return $imageSourceHandlerFn.Invoke()[-1]
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
elseif (!$imagePath) {
    $overwrite = & Prompt.ps1 -Title "Icon Already Exists" -Message "Folder Already has icon. do you want to refresh it (Y) Get new one (N)?";
    if (!$overwrite) {
        # & "$($PSScriptRoot)/Remove-Icon.ps1" $directoryPath;
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

timeout.exe 15;