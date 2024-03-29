function ParseArgs {
    param ($list, [string]$key)
    $value = $list | Where-Object { $null -ne $_ -and $_.StartsWith("$key=") };
    if (!$value) { return $null; }
    return $value -replace "$key=", ""
}

$file = ParseArgs -list $args -key "file";
$delayMilliseconds = [int](ParseArgs -list $args -key "delayMilliseconds");
$startAtTime = [double](ParseArgs -list $args -key "startAtTime");


function ParseFile() {
    $text = Get-Content -LiteralPath $file;
    $newContent = New-Object System.Collections.Generic.List[System.Object];
    $part = New-Object System.Collections.Generic.List[System.Object];
    for ($i = 0; $i -lt $text.Count; $i++) {
        $line = $text[$i];
        if ($line -eq "") {
            if ($part.Count -gt 0) {
                $newContent.Add($part) | Out-Null;
                $part = New-Object System.Collections.Generic.List[System.Object];
            }
            continue;
        }
        $part.Add($line) | Out-Null;
    }

    return $newContent | Sort-Object {
        return [int]($_[0])
    };   
}

$delayTimeSpan = [timespan]::FromMilliseconds($delayMilliseconds)
$delayMilliseconds = [System.Math]::Abs($delayMilliseconds);
# Function to adjust time
function Adjust-Time {
    param (
        [string]$time
    )
    
    # Convert the time string to TimeSpan
    $hours, $minutes, $seconds, $milliseconds = $time -split '[:,]' | ForEach-Object { [int]$_ }
    $timeSpan = [timespan]::FromMilliseconds($milliseconds);
    $timespan += [timespan]::FromHours($hours);
    $timespan += [timespan]::FromMinutes($minutes);
    $timespan += [timespan]::FromSeconds($seconds);
    $newTimeSpan = $timeSpan.Add($delayTimeSpan);
    if ($startAtTime) {
        if ($timeSpan.TotalSeconds -lt $startAtTime) {
            return $time;
        }
        if ($newTimeSpan.TotalSeconds -lt $startAtTime) {
            return -1;
        }
    }

    if ($newTimeSpan.TotalMilliseconds -le 0) {
        return -1
    }
    
    # Format the new time back to string
    return '{0:00}:{1:00}:{2:00},{3:000}' -f $newTimeSpan.Hours, $newTimeSpan.Minutes, $newTimeSpan.Seconds, $newTimeSpan.Milliseconds
}

$timeRegex = "(?<StartTime>\d+:\d+:\d+,\d+) --> (?<EndTime>\d+:\d+:\d+,\d+)"
$content = ParseFile;
$currentSubEntry = 1;
$finalContent = New-Object System.Collections.Generic.List[System.Object];
foreach ($sub in $content) {
    $times = $sub[1]
    $times -match $timeRegex  | Out-Null;
    $originalStartTime = $Matches["StartTime"];
    $startTime = Adjust-Time -time $originalStartTime -delay $delayMilliseconds;
    $originalEndTime = $Matches["EndTime"];
    $endTime = Adjust-Time -time $originalEndTime  -delay $delayMilliseconds;
    if ($startTime -eq -1 -or $endTime -eq -1) {
        continue;
    }
    $newTime = $times -replace $originalStartTime, $startTime -replace $originalEndTime, $endTime
    
    $finalContent.Add($currentSubEntry) | Out-Null;
    $finalContent.Add($newTime) | Out-Null;
    for ($i = 2; $i -lt $sub.Count; $i++) {
        $finalContent.Add($sub[$i]) | Out-Null;
    }
    $finalContent.Add("") | Out-Null;
    $currentSubEntry++;
}

$finalContent | Set-Content -LiteralPath $file -Encoding UTF8
