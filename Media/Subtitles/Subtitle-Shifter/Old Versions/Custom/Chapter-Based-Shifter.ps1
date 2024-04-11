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
            $chapter = @{
                Start  = $start
                End    = $end
                Length = $end - $start
                Title  = $ffmpegOutput[++$i] -replace "title=", ""
            }
            $chapters += $chapter
        }
    }

    return $chapters;
}

function ParseChapters {
    param (
        $chapters
    )
    
    $openeingChapter = $chapters | Where-Object { $_.Title -match "(?i)(^Op\d+ - )|(Opening)" }
    if (!$openeingChapter) {
        return @{
            OpeneingChapter = $null
            EpisodeChapter = $null
        };
    }
    
    $chapters = $chapters | Where-Object {
        !($_ -eq $openeingChapter -or $_.Title -match "(?i)(^ED\d+ - )|(Ending)")
    } | Sort-Object -Property Start, End, Length

    $episodeChapter = $chapters | Where-Object { $_.Title -in $startFromChapterNames }
    if ($episodeChapter) {
        return @{
            OpeneingChapter = $openeingChapter
            EpisodeChapter = $episodeChapter
        };
    }

    $intoChapter = $chapters | Where-Object { $_.Title -in $startAtTheEndOfChapterNames }
    $index = [Array]::IndexOf($chapters, $intoChapter);
    $episodeChapter = $chapters[$index + 1];
    if ($episodeChapter) {
        return @{
            OpeneingChapter = $openeingChapter
            EpisodeChapter = $episodeChapter
        };
    }

    return @{
        OpeneingChapter = $openeingChapter
        EpisodeChapter = $null
    };
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
    [System.ConsoleColor]::Magenta
);

$ffmpegPath = "D:\Programs\Media\Tools\yt\ffmpeg.exe"
$handlers = @{
    ".ass" = "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Subtitles\Subtitle-Shifter/handlers/Ass-Subtitle-Shifter.ps1";
    ".srt" = "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Subtitles\Subtitle-Shifter/handlers/Srt-Subtitle-Shifter.ps1";
};

$startFromChapterNames = @("Episode") + ((Read-Host "Please enter chapter names to start delaying from its start?") -split ",") | ForEach-Object { if ($_) { return $_.Trim() } };
$startAtTheEndOfChapterNames = @("Intro") + ((Read-Host "Please enter chapter names to start delaying from its end?") -split ",") | ForEach-Object { if ($_) { return $_.Trim() } };
$global:delayIfIntroFound = [double](Read-Host "delay If Intro Found?");
$global:delayIfEpisodeFound = [double](Read-Host "delay If Episode Found?");

function Handle {
    param ($videoFile, $subFile, $handler)
    $chapters = GetChapters -path $videoFile;
    Write-Host ($chapters.Title) -Separator ", "
    $chapters = ParseChapters -chapters $chapters
    $startFromSecond = 0;
    $delayMilliseconds = 0;
    $openeingChapter = $chapters.OpeneingChapter
    if (!$openeingChapter) {
        Write-Host "Can't find Opening chapter for $videoFile" -ForegroundColor Red -BackgroundColor White;
        return;
    }
    else {
        $delayMilliseconds = $openeingChapter.Length * 1000 * -1;
    }

    $episodeChapter = $chapters.EpisodeChapter;
    if ($episodeChapter) {
        $startFromSecond = $episodeChapter.Start;
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