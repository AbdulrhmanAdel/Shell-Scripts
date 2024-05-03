# @echo off
# set STAXRIP="path\to\StaxRip.exe"
# set TEMPLATE="path\to\your\template.srip"
# set INPUT="path\to\input\video.mp4"
# set OUTPUT="path\to\output\video.mp4"

# %STAXRIP% -load-template %TEMPLATE% -encode -auto-exit -hide -output "%OUTPUT%" "%INPUT%"


$source = & Options-Selector.ps1 -options @("All", "Videos", "Images", "Course") --multi;
$modulesPath = "$($PSScriptRoot)\Modules";
if ($source -eq "Course" ) {
    $scriptPath = "$modulesPath/Course-Compressor.ps1";
    & $scriptPath $args[0];
    EXIT;
}

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

if ( -and $images.Count) {
    $command = (@("""$modulesPath\Image-Compressor.ps1""") + $images) -join " ";
    Write-Host "ENCODING IMAGES" -ForegroundColor Magenta;
    Start-Process  pwsh.exe -ArgumentList $command -Wait -NoNewWindow;
    CopyTransformedToOriginalFolder -files $images;
    Write-Host "FINISH ENCODING IMAGES" -ForegroundColor Magenta;
}

if ($source -match "All|Videos" -and $videos.Count) {
    $command = (@("""$modulesPath\Video-Compressor.ps1""") + $videos) -join " ";

    # & """$modulesPath\Video-Compressor.ps1""" 
    Write-Host "ENCODING Videos" -ForegroundColor Magenta;
    Start-Process  pwsh.exe -ArgumentList $command -Wait -NoNewWindow;
    CopyTransformedToOriginalFolder -files $videos;
    Write-Host "FINISH ENCODING VIDEOS" -ForegroundColor Blue;
}

