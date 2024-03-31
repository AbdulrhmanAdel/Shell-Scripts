$ffmpegPath = "D:\Programs\Media\Tools\yt\ffmpeg.exe"
$file = "D:\Watch\Anime\3-GATSU NO LION\Season 2\3-gatsu no Lion II - 22 (BD 720p) (Commie) (A0E57FC8).mkv"
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

    $openeingChapter = $chapters | Where-Object { $_.Title -match "(?i)(^Op - )|(Opening)" }
    $realChapters = $chapters | Where-Object {
        $_ -ne $openeingChapter
    } | Sort-Object -Property Start, End, Length
    
    for ($i = 0; $i -lt $realChapters.Count; $i++) {
        $chapter = $realChapters[$i];
        if ($i -eq $realChapters.Count - 1) {
            $chapter.Diff = 0;
            continue;
        }
        $nextChapter = $realChapters[$i + 1];
        $chapter.Diff = $nextChapter.Start - $chapter.End;
    }

    # Output the chapters array
    return @($openeingChapter) + $realChapters
}

foreach ($file in ($args | Where-Object { $_ -match ".*(.mkv)$" })) {
    $chapters = GetChapters -path $file | Sort-Object -Property Start, End;
    $openeingChapter = $chapters | Where-Object { $_.Title -match "(?i)(^Op - )|(Opening)" }
    Write-Host $file -ForegroundColor Blue;
    Write-Host "$($openeingChapter.Title): $($openeingChapter.Start) -> $($openeingChapter.End) With Length $($openeingChapter.Length)"
    $chapters = $chapters | Where-Object {
        $_ -ne $openeingChapter
    }
    $totalDiff = 0;
    foreach ($chapter in $chapters) {
        if ($chapter.Diff -eq 0) {
            continue;
        }

        if ($totalDiff -gt 0) {
            $totalDiff -= $chapter.Diff

        }
        else {
            $totalDiff += $chapter.Diff
        }
    }
    Write-Host "totalDiff: $totalDiff";
    foreach ($chapter in $chapters) {
        Write-Host "$($chapter.Title): $($chapter.Start) -> $($chapter.End) With Length $($chapter.Length), DIFF $($chapter.Diff)"
    }
}

function ForceExit {
    Read-Host "Force Close The Window";
    ForceExit;
}

ForceExit