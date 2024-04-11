#region External Programs

$getChapterScriptPath = "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Shared\Get-Chapters.ps1";

#endregion

($args | Where-Object { $_ -match ".*(.mkv)$" })  | ForEach-Object {
    $file = $_;
    Write-Host $file -ForegroundColor Blue;
    $chapters = & $getChapterScriptPath $file;
    Write-Host ($chapters | ForEach-Object { return $_.Title }) -Separator ", " -ForegroundColor Green;
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