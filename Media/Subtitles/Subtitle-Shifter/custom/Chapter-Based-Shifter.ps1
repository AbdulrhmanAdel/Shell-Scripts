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


$base = (Get-Item -LiteralPath $PSScriptRoot).Directory;
$handlers = @{
    ".ass" = "$base/handlers/Ass-Subtitle-Shifter.ps1";
    ".srt" = "$base/handlers/Srt-Subtitle-Shifter.ps1";
};

function Get-Chapters {
    param (
        $path
    )
    
    return & Get-Chapters.ps1 $path;
}

function Handle {
    param ($videoFile, $subFile, $handler)
    $chapters = Get-Chapters -path $videoFile;
    Write-Host "Chapters: " -ForegroundColor Green -NoNewline;
    Write-Host ($chapters.Title) -Separator ", "
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

    if (!$delayMilliseconds) {
        return;
    }

    $delayMilliseconds = -1 * $delayMilliseconds;
    $startFromSecond = $startFromSecond / 1000;
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
    Write-Host "Start Handling File: $file" -ForegroundColor $color;
    Handle `
        -handler $handlers[$info.Extension] `
        -videoFile $videInfo `
        -subFile $file;
    Write-Host "End Handling File: $file" -ForegroundColor $color;
}

Read-Host "Press Any Key To Exit."
timeout.exe 20;