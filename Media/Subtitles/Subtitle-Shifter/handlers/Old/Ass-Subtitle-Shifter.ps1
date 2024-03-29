function ParseArgs {
    param ($list, [string]$key)
    $value = $list | Where-Object { $null -ne $_ -and $_.StartsWith("$key=") };
    if (!$value) { return $null; }
    return $value -replace "$key=", ""
}

$file = ParseArgs -list $args -key "file";
$delayMilliseconds = [int](ParseArgs -list $args -key "delayMilliseconds");
$cutFrom = ParseArgs -list $args -key "cutFrom";
$cutTo = ParseArgs -list $args -key "cutTo";
$startAtWord = ParseArgs -list $args -key "startAtWord";

$handleAction = {
    param ($line)
    $newContent.Add((ShiftLine -line $line)) | Out-Null;
}

if ($cutFrom -and $cutTo) {
    $handleAction = {
        $script:lastTime = $null;
        return {
            param ($line)
            $lineContent = $Matches[3];
            if ($lineContent -eq $startAtWord) {
                Write-Output "Line Found $line"
                $script:startAtWordEncountered = $true;
            }

            if ($script:startAtWordEncountered) {
                $newContent.Add((ShiftLine -line $line)) | Out-Null;
                return;
            }

            $newContent.Add($line) | Out-Null; 
        }
    }.Invoke();
}

if ($startAtWord) {
    $handleAction = {
        $script:startAtWordEncountered = $false;
        return {
            param ($line)
            $lineContent = $Matches["Text"];
            if ($lineContent -eq $startAtWord) {
                Write-Output "Line Found $line"
                $script:startAtWordEncountered = $true;
            }

            if ($script:startAtWordEncountered) {
                $newContent.Add((ShiftLine -line $line)) | Out-Null;
                return;
            }

            $newContent.Add($line) | Out-Null; 
        }
    }.Invoke();
}


function AdjustTime {
    param (
        [string]$time,
        [int]$delay
    )
    
    # Parse the time string and convert it to TimeSpan
    $timeSpan = [timespan]::ParseExact($time, "h\:mm\:ss\.ff", $null)
    # Convert delay from milliseconds to TimeSpan
    $delayTimeSpan = [timespan]::FromMilliseconds($delay)
    # Adjust the time
    $newTimeSpan = $timeSpan.Add($delayTimeSpan)
    # Format the new time back to string
    return $newTimeSpan.ToString("hh\:mm\:ss\.ff")
}

function ShiftLine {
    param ([string]$line)
    $originalStartTime = $Matches["StartTime"];
    $startTime = AdjustTime -time $originalStartTime -delay $delayMilliseconds;
    $originalEndTime = $Matches["EndTime"];
    $endTime = AdjustTime -time $originalEndTime  -delay $delayMilliseconds
    return $line -replace $originalStartTime, $startTime -replace $originalEndTime, $endTime
}

$content = Get-Content -LiteralPath $file | Sort-Object {
    
};
$newContent = New-Object System.Collections.Generic.List[System.Object];
foreach ($line in $content) {
    if ($line -match "Dialogue: (?<Layer>\d+),(?<StartTime>\d{1,2}:\d{2}:\d{2}\.\d{2}),(?<EndTime>\d{1,2}:\d{2}:\d{2}\.\d{2}),(?<Style>[^,]*),(?<Name>[^,]*),(?<MarginL>\d+),(?<MarginR>\d+),(?<MarginV>\d+),(?<Effect>[^,]*),(?<Text>.+)") {
        $handleAction.Invoke($line);
    }
    else {
        $newContent.Add($line) | Out-Null;
    }
}
# Save the adjusted subtitles to a new file
$newContent | Set-Content -LiteralPath $file -Encoding UTF8;
