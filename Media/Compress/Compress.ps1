# @echo off
# set STAXRIP="path\to\StaxRip.exe"
# set TEMPLATE="path\to\your\template.srip"
# set INPUT="path\to\input\video.mp4"
# set OUTPUT="path\to\output\video.mp4"

# %STAXRIP% -load-template %TEMPLATE% -encode -auto-exit -hide -output "%OUTPUT%" "%INPUT%"

function Run {
    param (
        $files,
        $scriptPath
    )
    
    $command = (@("""$modulesPath\$scriptPath""") + $files) -join " ";
    Write-Host "ENCODING Using $scriptPath" -ForegroundColor Magenta;
    Start-Process  pwsh.exe -ArgumentList $command -Wait -NoNewWindow;
    # CopyTransformedToOriginalFolder -files $images;
    Write-Host "FINISH ENCODING" -ForegroundColor Magenta;
}

$source = & Options-Selector.ps1 -options @("All", "Videos", "Images", "Course", "Audio");
$modulesPath = "$($PSScriptRoot)\Modules";
if ($source -eq "Course" ) {
    $scriptPath = "$modulesPath/Course/Course-Compressor.ps1";
    & $scriptPath $args[0];
    EXIT;
}

$videos = @();
$images = @();
$audio = @();
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
    elseif ($_ -match "\.(mp3|opus|m4a)$") {
        $audio += """$($_)""";   
    }
};

if ($source -match "All|Images" -and $images.Count) {
    Run -files $images -scriptPath "Image-Compressor.ps1";
}
if ($source -match "All|Audio" -and $audio.Count) {
    Run -files $audio -scriptPath "Audio-Compressor.ps1";
}
if ($source -match "All|Videos" -and $videos.Count) {
    Run -files $videos -scriptPath "Video-Compressor.ps1";
}

