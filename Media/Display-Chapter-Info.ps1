($args | Where-Object { $_ -match ".*(.mkv)$" })  | ForEach-Object {
    $file = $_;
    Write-Host $file -ForegroundColor Blue;
    $chapters = & Get-Chapters.ps1 $file;
    if (!$chapters) {
        Write-Host "NO CHAPTERS FOUND" -ForegroundColor Red;
        return;
    }
    Write-Host ($chapters | ForEach-Object { return $_.Title }) -Separator ", " -ForegroundColor Green;

    $startFromSecond = 0;
    $delayMilliseconds = 0;
    $foundSegmentedChapter = $false;
    foreach ($c in $chapters) {
        if ($c.Title -match "(?i)Ending|ED") {
            break;
        }
        if ($c.SegmentId) {
            $foundSegmentedChapter = $true;
            $delayMilliseconds += $c.Duration;
            continue;
        }

        if ($foundSegmentedChapter) {
            break;
        }
        
        $startFromSecond += $c.Duration;
    }
    Write-Host "StartFromSecond: " -NoNewline
    Write-Host "$($startFromSecond / 1000), " -ForegroundColor Red -NoNewline
    Write-Host "DelayMilliseconds: " -NoNewline
    Write-Host "$delayMilliseconds" -ForegroundColor Red

    foreach ($chapter in $chapters) {

        Write-Host "$($chapter.Title): $($chapter.Start) -> $($chapter.End)," -NoNewline;
        $hasSegment = !!$chapter.SegmentId;
        $color = $hasSegment ? [System.ConsoleColor]::Red :[System.ConsoleColor]::White;
        Write-Host " Has Segment: $($hasSegment)" -NoNewline -ForegroundColor $color;
        Write-Host ", With Length $($chapter.Duration)";
    }

    Write-Host "==========" -ForegroundColor Green;
}

function ForceExit {
    Read-Host "Force Close The Window";
    ForceExit;
}

ForceExit