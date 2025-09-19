[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$source = & Single-Options-Selector.ps1 -options @("All", "Videos", "Images", "Course", "Audio");
$modulesPath = "$($PSScriptRoot)\Modules";
if ($source -eq "Course" ) {
    $scriptPath = "$modulesPath/Course/Course-Compressor.ps1";
    & $scriptPath -Paths $Files;
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

$Files | ForEach-Object {
    if (!(Test-Path -LiteralPath $_)) {
        return $false; 
    }
    if ($_ -match "\.(mkv|mp4|avi|webm)$") {
        $videos += $_;   
    }
    elseif ($_ -match "\.(jpg|jpeg|png|gif|bmp|heic|dng)$") {
        $images += $_;   
    }
    elseif ($_ -match "\.(mp3|opus|m4a)$") {
        $audio += $_;   
    }
    elseif (Test-Path -LiteralPath $_ -PathType Container) {
        $audio += $_; 
    }
};

if ($source -match "All|Images" -and $images.Count) {
    & "$modulesPath\Image-Compressor.ps1" -Files $images;
}

if ($source -match "All|Audio" -and $audio.Count) {
    & "$modulesPath\Audio-Compressor.ps1" -Files $audio;
}
if ($source -match "All|Videos" -and $videos.Count) {
    & "$modulesPath\Video-Compressor.ps1" -Files $videos;
}