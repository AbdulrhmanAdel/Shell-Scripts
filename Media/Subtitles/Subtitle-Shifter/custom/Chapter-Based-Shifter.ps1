$ffmpegPath = "D:\Programs\Media\Tools\yt\ffmpeg.exe"
$chapterNames = @("Intro");
$handlers = @{
    ".ass" = "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Subtitles\Subtitle-Shifter/handlers/Ass-Subtitle-Shifter.ps1";
    ".srt" = "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Subtitles\Subtitle-Shifter/handlers/Srt-Subtitle-Shifter.ps1";
};

#region function

function GetChapters {
    param($path)
    $ffmpegOutput = & $ffmpegPath -loglevel error -i $path -f ffmetadata -; 
    $chapters = @()
    for ($i = 0; $i -lt $ffmpegOutput.Length; $i++) {
        if ($ffmpegOutput[$i] -match "\[CHAPTER\]") {
            $timebase = [int64]($ffmpegOutput[++$i] -replace "TIMEBASE=1/", "")
            $start = [int64]($ffmpegOutput[++$i] -replace "START=", "") / $timebase;
            $end = [int64]($ffmpegOutput[++$i] -replace "END=", "") / $timebase;
            $lenght
            $chapter = @{
                Start  = $start
                End    = $end
                Length = $end - $start
                Title  = $ffmpegOutput[++$i] -replace "title=", ""
            }
            $chapters += $chapter
        }
    }

    # Output the chapters array
    return $chapters
}

#endregion
$global:manualDelayInMiliSeconds = $null;
function Handle {
    param ($videoFile, $subFile, $handler)
    $chapters = GetChapters -path $videoFile;
    $startFromSecond = 0;
    $openeingChapter = $chapters | Where-Object { $_.Title -match "(?i)(^Op - )|(Opening)" }
    if (!$openeingChapter) {
        Write-Host "Can't find Opening chapter for $videoFile" -ForegroundColor Red -BackgroundColor White;

        if ($null -eq $global:manualDelayInMiliSeconds) {
            $global:manualDelayInMiliSeconds = [double](Read-Host "Please Enter Delay in seconds?");
            if (!$global:manualDelayInMiliSeconds) {
                return;
            }
        }
        $delayMilliseconds = $global:manualDelayInMiliSeconds;
    }
    else {
        $delayMilliseconds = $openeingChapter.Length * 1000 * -1;
    }

    $episodeChapter = $chapters | Where-Object { $_.Title -match "Episode|(Part(-| )A)" }
    if ($episodeChapter) {
        $startFromSecond = $episodeChapter.Start;
    }
    else {
        $targetChapter = $chapters | Where-Object { $_.Title -in $chapterNames }
        if ($targetChapter) {
            $startFromSecond = $targetChapter.End
        }
    }

    if ($startFromSecond) {
        $startFromSecond = "startFromSecond=$($startFromSecond)";
        & $handler  "file=$subFile" $startFromSecond "delayMilliseconds=$delayMilliseconds";
    }
    else {
        & $handler  "file=$subFile" "delayMilliseconds=$delayMilliseconds";
    }
}

foreach ($file in $args) {
    $info = Get-Item -LiteralPath $file;
    $videInfo = "$($info.Directory)/$($info.Name -replace $info.Extension, ".mkv")"
    Handle `
        -handler $handlers[$info.Extension] `
        -videoFile $videInfo `
        -subFile $file;
}

Read-Host "Press Any Key To Exit."
timeout.exe 20;