#region External Programs
$getChapterScriptPath = "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Shared\Get-Chapters.ps1";
function Get-Chapters {
    param (
        $path
    )
    
    return & $getChapterScriptPath $path;
}

#endregion

$colors = @(
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

function Handle {
    param ($videoFile)
    $chapters = Get-Chapters -path $videoFile;
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
    Write-Host "$startFromSecond, " -ForegroundColor Red -NoNewline
    Write-Host "DelayMilliseconds: " -NoNewline
    Write-Host "$delayMilliseconds" -ForegroundColor Red
}

$files = $args | Where-Object { $_ -match ".*(mkv)$" }
foreach ($file in $files) {
    $color = Get-Random $colors;
    Write-Host "File: $file" -ForegroundColor $color;
    Handle -videoFile $file;
    Write-Host "===========================================" -ForegroundColor $color;
}

Read-Host "Press Any Key To Exit."
timeout.exe 20;