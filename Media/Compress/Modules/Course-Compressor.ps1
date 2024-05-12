#region Functions


# $targetBitRate = [int](& Text-Input.ps1 -message "Please Enter Target BitRate in KB" -type "number")
$targetBitRate = [int](Read-Host "Please Enter Target BitRate in KB");
Write-Host "Target BitRate $targetBitRate";
function Compress {
    param (
        $inputPath,
        $outputPath
    )
    $audioFormat = "opus";
    # 720x1280
    $width = 1280;
    $height = 720;
    $arguments = @(
        "-T",
        "--multi-pass",
        "--optimize",
        "--width", $width,
        "--height", $height,
        "--verbose=0",
        "--encoder-preset", "fast",
        "--aencoder", $audioFormat,
        "--ab", 64,
        "--arate", 24
    );

    $info = & MediaInfo --Output=JSON $inputPath | ConvertFrom-Json;
    $videoTrack = $info.media.track[1];
    # $videSize = ([double]$videoTrack.StreamSize) / (1024 * 1024);
    $frameRate = [double]$videoTrack.FrameRate;
    if ($frameRate -gt 30) {
        $arguments += @("--rate", 30, "--cfr");
    }

    $bitRate = ([double]$videoTrack.BitRate) / 1000;
    $videoBitRate = $targetBitRate;
    if ($bitRate -gt $videoBitRate) {
        $arguments += @("-b", $videoBitRate);
    }

    $encodedLibrary = $videoTrack.Encoded_Library_Name;
    if ($encodedLibrary -eq "x264") {
        $arguments += @("--encoder", "x264");
    }
    else {
        $arguments += @("--encoder", "x265");
    }
    
    $arguments += @("-i", """$inputPath""", "-o", """$outputPath""");
    Start-Process handbrake -ArgumentList $arguments -NoNewWindow -PassThru -Wait;
}


function Handle {
    param (
        $sectionOutputPath,
        $file
    )
    $fileOutputPath = "$sectionOutputPath/$($file.Name)";
    if (Test-Path -LiteralPath $fileOutputPath) {
        continue;
    }

    if ($file.Extension -notin @(".mkv", ".mp4")) {
        Copy-Item -LiteralPath $file.FullName -Destination $sectionOutputPath -Force;
        continue;
    }

    Compress -inputPath "$($file.FullName)" -outputPath $fileOutputPath;
}

#endregion

# Compress -inputPath "D:\Programming\Courses\Udemy - Fundamentals of Operating Systems 2024-4\1. Before we start\1. Welcome.mp4" `
#     -outputPath "D:\Programming\Courses\1. Welcome 7.mp4"

$coursePath = $args[0];
$courseInfo = Get-Item -LiteralPath $coursePath;

if ($courseInfo -isnot [System.IO.DirectoryInfo]) {
    if ($courseInfo.Extension -notin @(".mkv", ".mp4")) {
        EXIT;
    }

    $outputFile = "$($courseInfo.Directory.FullName)\" + $courseInfo.Name.Replace($courseInfo.Extension, " Converted$($courseInfo.Extension)");
    Compress -inputPath $courseInfo.FullName -outputPath $outputFile;
    EXIT;
}

$outputPath = $courseInfo.FullName.Replace($courseInfo.Name, $courseInfo.Name + " (Converted)");
if (!(Test-Path -LiteralPath $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null;
}

$folders = Get-ChildItem -LiteralPath $coursePath;
foreach ($folder in $folders) {
    if ($folder -is [System.IO.FileInfo]) {
        Handle -file $folder -sectionOutputPath $outputPath;
        continue;
    }

    $sectionOutputPath = "$outputPath/$($folder.Name)";
    if (!(Test-Path -LiteralPath $sectionOutputPath)) {
        New-Item -Path $sectionOutputPath -ItemType Directory -Force | Out-Null;
    }

    $files = Get-ChildItem -LiteralPath $folder.FullName -File;
    foreach ($file in $files) {
        Handle -file $file -sectionOutputPath $sectionOutputPath;
        continue;
    }
}
