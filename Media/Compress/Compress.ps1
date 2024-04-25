$videos = @();
$images = @();

function CopyTransformedToOriginalFolder {
    param (
        $files
    )

    $files | ForEach-Object {
        $path = $_;
        $info = Get-Item -LiteralPath $path;
        $originalFolder = "$($info.Directory.FullName)\Original";
        if (Test-Path -LiteralPath $originalFolder) {
            return;
        }
    
        New-Item -Path $originalFolder -ItemType Directory;
        Move-Item -Path $path -Destination $originalFolder
    }
}

$args | ForEach-Object {
    if (!(Test-Path -LiteralPath $_)) {
        return $false; 
    }

    if ($_ -match "\.(mkv|mp4|avi|webm)$") {
        $videos += """$($_)""";   
    }
    elseif ($_ -match "\.(jpg|jpeg|png|gif|bmp|heic)$") {
        $images += """$($_)""";   
    }
};

$source = & "Options-Selector.ps1" @("All", "Videos", "Images");
$modulesPath = "$($PSScriptRoot)\Modules";
if ($source -match "All|Images" -and $images.Count) {
    $command = (@("""$modulesPath\Image-Compressor.ps1""") + $images) -join " ";
    Write-Host "ENCODING IMAGES" -ForegroundColor Magenta;
    Start-Process  pwsh.exe -ArgumentList $command -Wait -NoNewWindow;
    CopyTransformedToOriginalFolder -files $images;

    Write-Host "FINISH ENCODING IMAGES" -ForegroundColor Magenta;
}
if ($source -match "All|Videos" -and $videos.Count) {
    $command = (@("""$modulesPath\Video-Compressor.ps1""") + $videos) -join " ";
    Write-Host "ENCODING Videos" -ForegroundColor Magenta;
    Start-Process  pwsh.exe -ArgumentList $command -Wait -NoNewWindow;
    CopyTransformedToOriginalFolder -files $videos;
    Write-Host "FINISH ENCODING VIDEOS" -ForegroundColor Blue;
}