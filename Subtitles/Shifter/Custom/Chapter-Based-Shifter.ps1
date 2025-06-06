[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

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



$base = Split-Path $PSScriptRoot
$handlers = @{
    ".ass" = "$base/handlers/Ass-Subtitle-Shifter.ps1";
    ".srt" = "$base/handlers/Srt-Subtitle-Shifter.ps1";
};


function Handle {
    param ($videoFile, $subFile, $handler)
    $chapters = & Get-Chapters.ps1 $videoFile;
    if (!$chapters) {
        Write-Host "NO CHAPTERS FOUND" -ForegroundColor Red;
        return;
    }
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

        if ($foundSegmentedChapter -and $delayMilliseconds -ne 0) {
            break;
        }
        
        $startFromSecond += $c.Duration;
    }

    if (!$delayMilliseconds) {
        return;
    }

    $delayMilliseconds = -1 * $delayMilliseconds;
    $delayMilliseconds = -90000;
    $startFromSecond = $startFromSecond / 1000;
    if ($startFromSecond) {
        & $handler  -file $subFile -startFromSecond $startFromSecond -delayMilliseconds $delayMilliseconds;
    }
    else {
        & $handler  -file $subFile -delayMilliseconds $delayMilliseconds;
    }
}

$files = $Files | Where-Object { $_ -match ".*(ass|srt)$" }
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