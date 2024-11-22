[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]
    $DirectoryPath,
    $ImagePath,
    [switch]$SkipTimeOut
)

function OpenBrowser {
    param (
        [string]$Website,
        [switch]$PickFirstImage
    )

    if (!$Website -or $Website -eq "") {
        $Website = & Single-Options-Selector.ps1 `
            -Options @("Google", "Yandex", "Deviantart", "Bing", "DuckDuckGo") `
            -Title "Select Icon Website" -MustSelectOne;
    }

    $replaceText = "\[(FitGirl|Dodi).*\]";
    $name = $directory.Name -replace $replaceText, "";
    $isGame = $directory.FullName.Contains("Game");
    $query = "$($name) $($isGame ? 'Game' : '') Icon";
    $link = $null;
    $Options = @{
        path           = [System.Web.HttpUtility]::UrlEncode($directory.FullName)
        pickFirstImage = $PickFirstImage
    }

    $Options.Keys.ForEach({
            $Value = $Options[$_];
            if ($Value) {
                $query += "&" + $_ + "=" + $Value
            }
        });

    switch ($Website) {
        "Google" { $link = "https://www.google.com/search?tbm=isch&q=$query"; break; }
        "Yandex" { $link = "https://yandex.com/images/search?ih=256&iw=256&isize=eq&itype=png&text=$query"; break; }
        "Deviantart" { $link = "https://www.deviantart.com/search/deviations?q=$query&order=most-recent"; break; }
        "Bing" { $link = "https://www.bing.com/images/search?q=$query"; break; }
        "DuckDuckGo" { $link = "https://duckduckgo.com/?t=h_&iax=images&ia=images&iaf=type:transparent,layout:Square&q=$query"; break; }
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
    "FromBrowser" = {
        OpenBrowser;
        EXIT;
    }
    "FromLink"    = { 
        if (Prompt.ps1 -Message "Open Browser?") {
            OpenBrowser -Website "Yandex";
        }
        $imageUrl = Read-Host "Please Enter Icon Url";
        if ($imageUrl) {
            return DonwloadImage -imageUrl $imageUrl; 
        }

        return $null;
    }
    "FromPath"    = { 
        return File-Picker.ps1 `
            -InitialDirectory $directory.Parent.FullName `
            -ShowHiddenFiles `
            -Retry 1 `
            -Filter "Images |*.ico;*.png;*.jpg" 
    }
};

function GetIamgePath {
    $imageSource ??= & Single-Options-Selector.ps1 `
        -Options $imageSourceHandlers.Keys `
        -Title "Select Icon Source" `
        -MustSelectOne;

    $imageSourceHandlerFn = $imageSourceHandlers[$imageSource];
    return $imageSourceHandlerFn.Invoke()[-1];
} 

$directory = Get-Item -LiteralPath $DirectoryPath -Force;
$iconPath = "$($directory.FullName)\$($directory.Name.Trim()).ico";
$folderHasIcon = Test-Path -LiteralPath $iconPath;
if ($folderHasIcon -and !$ImagePath) {
    Write-Host "Folder Already Has Icon. Overriding IT" -ForegroundColor Red;
    # $overwrite = & Prompt.ps1 -Title "Icon Already Exists" -Message "Folder Already has icon. do you want to overwrite it?";
    # if (!$overwrite) {
    #     # & "$PSScriptRoot/Refresh-Icon.ps1" -FolderPath $DirectoryPath;
    #     return;
    # }
}

if (!$ImagePath) {
    while (!$ImagePath) {
        $ImagePath = GetIamgePath
    }
}


if ($ImagePath.EndsWith(".ico")) {
    Copy-Item -LiteralPath $ImagePath -Destination $iconPath -Force;
}
else {
    & "$($PSScriptRoot)/Utils/Convert-Png-To-Ico.ps1" -ImagePath "$ImagePath" -SavePath "$iconPath";
}

# Hide the Icon
$iconFile = Get-Item -LiteralPath $iconPath -Force;
attrib.exe +h +s +r "$iconFile";

& "$PSScriptRoot/Set-Icon.ps1" $directory.FullName "./$($iconFile.Name)";
Write-Host "DONE Image Converted Successfully" -ForegroundColor Green;

if ($SkipTimeOut) {
    EXIT;
}

timeout.exe 15;