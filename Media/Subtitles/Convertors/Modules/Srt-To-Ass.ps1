$files = $args[0] | Where-Object { $_ -match "\.srt" };
$encoding = $args[1];
#region functions 
function ParseTimeSpan {
    param (
        $time
    )
    
    $hours, $minutes, $seconds, $milliseconds = $time -split '[:,]' | ForEach-Object { [int]$_ }
    $timeSpan = [timespan]::FromMilliseconds($milliseconds);
    $timespan += [timespan]::FromHours($hours);
    $timespan += [timespan]::FromMinutes($minutes);
    $timespan += [timespan]::FromSeconds($seconds);
    return $timeSpan;
}

function ParseDialogue {
    param ($line)
    return @{
        StartTime       = ParseTimeSpan -time $Matches["StartTime"]
        EndTime         = ParseTimeSpan -time $Matches["EndTime"]
        OriginalContent = $line
    }
    
}
function SerializeTimeSpan ($timeSpan) {
    return $timeSpan.ToString("hh\:mm\:ss\.ff");
}

#endregion
$header = @(
    "[Script Info]",
    "Title: العربية",
    "ScriptType: v4.00+",
    "Collisions: Normal",
    "PlayResX: 640",
    "PlayResY: 360",
    "WrapStyle: 0",
    "",
    "[V4+ Styles]",
    "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, Strikeout, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding",
    "Style: Default, Adobe Arabic, 26, &H00FFFFFF, &H000000FF, &H00000000, &H00000000, -1, 0, 0, 0, 100, 100, 0, 0, 1, 1, 0, 2, 0010, 0010, 0020, 0",
    "",
    "[Events]"
    "Format: Layer,Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text"
);

$timeRegex = "(?<StartTime>\d+:\d+:\d+,\d+) --> (?<EndTime>\d+:\d+:\d+,\d+)"
function Convert($path) {
    $encoding = & Get-File-Encoding.ps1 $path;
    Write-Host "USED ENCODING $encoding" -ForegroundColor Green;
    $dialogues = New-Object System.Collections.Generic.List[System.Object];
    $content = (Get-Content -LiteralPath $file -Encoding $encoding);
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -eq "") {
            continue;
        }

        $endTextIndex = [Array]::IndexOf($content, "", $i);
        $line = $content[($i + 1)..($endTextIndex - 1)];
        $line[0] -match $timeRegex | Out-Null;
        $dialogues.Add((ParseDialogue -line $line))
        $i = $endTextIndex;
    }

    $newContent = New-Object System.Collections.Generic.List[System.Object];
    $dialogues | Sort-Object -Property StartTime | ForEach-Object {
        $start = SerializeTimeSpan -timeSpan $_.StartTime;
        $end = SerializeTimeSpan -timeSpan $_.EndTime;
        $text = $_.OriginalContent[1];
        $newContent.Add("Dialogue: 0,$start,$end,Default,AT,0,0,0,,$text") | Out-Null;
    }

    $finalContent = $header + $newContent;
    $fileName = $file -replace ".srt", ".ass";
    $finalContent | Set-Content -LiteralPath $fileName -Encoding $encoding
}



$removeSource = & Prompt.ps1 -title `
    "Remove Source" `
    -message "Do you want to remove source" `
    -defaultValue $false;
    
foreach ($file in $files) {
    Convert -path $file;
    if ($removeSource) {
        Remove-Item -LiteralPath $file -Force;
    }
}

timeout.exe 15;
