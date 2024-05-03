#region Functions

function Compress {
    param (
        $inputPath,
        $outputPath
    )
    
    $videoBitRate = 395;
    $rate = 30;
    $audioFormat = "opus";
    $arguments = @(
        "--encoder", "x265",
        "-T",
        "--optimize",
        "--width", 1280,
        "--height", 720,
        "-b", $videoBitRate,
        "--rate", $rate, "--cfr",
        "--verbose=0",
        "--encoder-preset", "fast",
        "--aencoder", $audioFormat,
        "--ab", 64,
        "--arate", 24
    );
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
