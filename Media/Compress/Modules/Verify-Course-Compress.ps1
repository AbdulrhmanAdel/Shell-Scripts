function GetVideoLength {
    param (
        $videoPath
    )

    $info = & MediaInfo --Output=JSON $videoPath | ConvertFrom-Json;
    return $info.media.track[0].Duration;
}

function Handle {
    param (
        $sectionOutputPath,
        $file
    )
    
    $fileOutputPath = "$sectionOutputPath/$($file.Name)";
    $isExists = Test-Path -LiteralPath $fileOutputPath;
    if (!$isExists) {
        Write-Host "CAN'T FIND File $fileOutputPath" -ForegroundColor Red
        return;
    }
    if ($file.Extension -notin @(".mkv", ".mp4")) {
        Write-Host "CORRECT File $fileOutputPath" -ForegroundColor Green
        return;
    }

    $sourceLength = GetVideoLength -videoPath $file.FullName;
    $targetLength = GetVideoLength -videoPath $fileOutputPath;
    $diff = ($sourceLength - $targetLength);

    if ($diff -lt 1 -and $diff -gt -1) {
        Write-Host "CORRECT File $fileOutputPath" -ForegroundColor Green
        return;
    }

    Write-Host "CAN'T FIND File $fileOutputPath" -ForegroundColor Red
}

$coursePath = $args[0];

$courseInfo = Get-Item -LiteralPath $coursePath;

$outputPath = $courseInfo.FullName.Replace($courseInfo.Name, $courseInfo.Name + " (Converted)");

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