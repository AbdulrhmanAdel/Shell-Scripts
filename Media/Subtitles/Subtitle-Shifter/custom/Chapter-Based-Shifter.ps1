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

$colors = @(
    [System.ConsoleColor]::Black,
    [System.ConsoleColor]::DarkBlue,
    [System.ConsoleColor]::DarkGreen,
    [System.ConsoleColor]::DarkCyan,
    [System.ConsoleColor]::DarkMagenta,
    [System.ConsoleColor]::DarkYellow,
    [System.ConsoleColor]::Gray,
    [System.ConsoleColor]::DarkGray,
    [System.ConsoleColor]::Blue,
    [System.ConsoleColor]::Green,
    [System.ConsoleColor]::Cyan,
    [System.ConsoleColor]::Magenta,
    [System.ConsoleColor]::Yellow
);

$ffmpegPath = "D:\Programs\Media\Tools\yt\ffmpeg.exe"
$chapterNames = @("Intro");
$handlers = @{
    ".ass" = "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Subtitles\Subtitle-Shifter/handlers/Ass-Subtitle-Shifter.ps1";
    ".srt" = "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Subtitles\Subtitle-Shifter/handlers/Srt-Subtitle-Shifter.ps1";
};

$startFromChapterNames = @("Episode");
$chapterNames = Read-Host "Please enter chapter names to start delaying from its start?";
if ($chapterNames) {
    $startFromChapterNames = $startFromChapterNames + ($chapterNames -split "," | ForEach-Object { return $_.Trim() })
}

$startAtTheEndOfChapterNames = @("Intro");
$chapterNames = Read-Host "Please enter chapter names to start delaying from its end?";
if ($chapterNames) {
    $startAtTheEndOfChapterNames = $startAtTheEndOfChapterNames + ($chapterNames -split "," | ForEach-Object { return $_.Trim() })
}


$global:customDelay = [double](Read-Host "Custom Delay?");
# $global:additionalDelayInMiliSeconds = [double](Read-Host "Please enter additional Delay In Seconds?") * 1000;
$global:manualDelayInMiliSeconds = $null;
function Handle {
    param ($videoFile, $subFile, $handler)
    $chapters = GetChapters -path $videoFile;
    Write-Host ($chapters.Title) -Separator ", "
    $startFromSecond = 0;
    $openeingChapter = $chapters | Where-Object { $_.Title -match "(?i)(^Op - )|(Opening)" }
    if (!$openeingChapter) {
        Write-Host "Can't find Opening chapter for $videoFile" -ForegroundColor Red -BackgroundColor White;
        return;
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

    $episodeChapter = $chapters | Where-Object { $startFromChapterNames -contains $_.Title }
    if ($episodeChapter) {
        $startFromSecond = $episodeChapter.Start;
    }
    else {
        Write-Host "Can't Find Chapters to Start From ts Start Search By $startFromChapterNames" -ForegroundColor Red;
        $introChapter = $chapters | Where-Object { $startAtTheEndOfChapterNames -contains $_.Title }
        if ($introChapter) {
            $startFromSecond = $introChapter.End
            if ($introChapter.End -lt $openeingChapter.End) {
                # $delayMilliseconds += 1000;
            }
        }
        else {
            Write-Host "Can't Find Chapters to Start From Its End Search By $startAtTheEndOfChapterNames" -ForegroundColor Red;
        }
    }
    
    $delayMilliseconds += $global:additionalDelayInMiliSeconds;
    
    if ($global:customDelay) {
        $delayMilliseconds = $global:customDelay;
    }
    if ($startFromSecond) {
        $startFromSecond = "startFromSecond=$($startFromSecond)";
        & $handler  "file=$subFile" $startFromSecond "delayMilliseconds=$delayMilliseconds";
    }
    else {
        & $handler  "file=$subFile" "delayMilliseconds=$delayMilliseconds";
    }
}

$files = $args | Where-Object { $_ -match ".*(ass|srt)$" }
foreach ($file in $files) {
    $info = Get-Item -LiteralPath $file;
    $videInfo = "$($info.Directory)/$($info.Name -replace $info.Extension, ".mkv")"
    $color = Get-Random $colors;
    Write-Host "Start Handling File: $subFile" -ForegroundColor $color;
    Handle `
        -handler $handlers[$info.Extension] `
        -videoFile $videInfo `
        -subFile $file;
    Write-Host "Start Handling File: $subFile" -ForegroundColor $color;
}

Read-Host "Press Any Key To Exit."
timeout.exe 20;