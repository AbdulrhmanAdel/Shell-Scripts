$files = $args | Where-Object { $_ -match "\.ass" };

function ToTimeSpan {
    param (
        $time
    )
    
    return [timespan]::ParseExact($time, "h\:mm\:ss\.ff", $null)
}

function ParseTimeSpan ($timeSpan) {
    return '{0:00}:{1:00}:{2:00},{3:000}' -f $timeSpan.Hours, $timeSpan.Minutes, $timeSpan.Seconds, $timeSpan.Milliseconds
}
function Convert($assFilePath) {
    $content = Get-Content -LiteralPath $assFilePath | ForEach-Object {
        if ($_ -match "Dialogue: (?<Layer>\d+),(?<StartTime>\d{1,2}:\d{2}:\d{2}\.\d{2}),(?<EndTime>\d{1,2}:\d{2}:\d{2}\.\d{2}),(?<Style>[^,]*),(?<Name>[^,]*),(?<MarginL>\d+),(?<MarginR>\d+),(?<MarginV>\d+),(?<Effect>[^,]*),(?<Text>.+)") {
            return @{
                Text      = $Matches["Text"] 
                StartTime = ToTimeSpan -time $Matches["StartTime"]
                EndTime   = ToTimeSpan -time $Matches["EndTime"]
                Layer     = $Matches["Layer"]
                Style     = $Matches["Style"]
                Name      = $Matches["Name"]
                MarginL   = $Matches["MarginL"]
                MarginR   = $Matches["MarginR"]
                MarginV   = $Matches["MarginV"]
                Effect    = $Matches["Effect"]
            }
        }
    } | Sort-Object -Property StartTime;
    $newContent = New-Object System.Collections.Generic.List[System.Object];
    for ($i = 0; $i -lt $content.Count; $i++) {
        $sub = $content[$i];
        $newContent.Add($i + 1) | Out-Null;
        $newContent.Add("$(ParseTimeSpan -timeSpan $sub["StartTime"]) --> $(ParseTimeSpan -timeSpan $sub["EndTime"])") | Out-Null;
        $newContent.Add($sub["Text"]) | Out-Null;
        $newContent.Add("") | Out-Null;
    }

    $srtFileName = $file -replace ".ass", ".srt";
    $newContent | Set-Content -LiteralPath $srtFileName
}

$removeSource = & Prompt.ps1 -title "Remove Source?" -message "Do You Want To Remove Source?" -defaultValue $false;
foreach ($file in $files) {
    Convert -assFilePath $file;
    if ($removeSource) {
        Remove-Item -LiteralPath $file -Force;
    }
}

timeout.exe 15;
