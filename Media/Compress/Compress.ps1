$videos = @();
$images = @();
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
    Write-Host "FINISH ENCODING IMAGES" -ForegroundColor Magenta;
}
if ($source -match "All|Videos" -and $videos.Count) {
    $command = (@("""$modulesPath\Video-Compressor.ps1""") + $videos) -join " ";
    Write-Host "ENCODING Videos" -ForegroundColor Magenta;
    Start-Process  pwsh.exe -ArgumentList $command -Wait -NoNewWindow;
    Write-Host "FINISH ENCODING VIDEOS" -ForegroundColor Blue;
}