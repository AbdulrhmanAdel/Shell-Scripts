$file = $args[1];
$delayMilliseconds = $args[2];

# Function to adjust time
function Adjust-Time {
    param (
        [string]$time,
        [int]$delay
    )
    
    # Convert the time string to TimeSpan
    $hours, $minutes, $seconds, $milliseconds = $time -split '[:,]' | ForEach-Object { [int]$_ }
    $timeSpan = [timespan]::FromMilliseconds($milliseconds);
    $timespan += [timespan]::FromHours($hours);
    $timespan += [timespan]::FromMinutes($minutes);
    $timespan += [timespan]::FromSeconds($seconds);
        
    # Convert delay from milliseconds to TimeSpan
    $delayTimeSpan = [timespan]::FromMilliseconds($delay)
    # Adjust the time
    $newTimeSpan = $timeSpan.Add($delayTimeSpan)
    # Format the new time back to string
    return '{0:00}:{1:00}:{2:00},{3:000}' -f $newTimeSpan.Hours, $newTimeSpan.Minutes, $newTimeSpan.Seconds, $newTimeSpan.Milliseconds
}

# Read the original subtitle file with UTF-8 encoding
$content = Get-Content -LiteralPath $file -Encoding UTF8

# Adjust the timestamps in the file
$adjustedContent = $content | ForEach-Object {
    if ($_ -match "(\d+:\d+:\d+,\d+) --> (\d+:\d+:\d+,\d+)") {
        $originalStartTime = $Matches[1];
        $startTime = Adjust-Time -time $originalStartTime -delay $delayMilliseconds;
        $originalEndTime = $Matches[2];
        $endTime = Adjust-Time -time $originalEndTime  -delay $delayMilliseconds
        return $_ -replace $originalStartTime, $startTime -replace $originalEndTime, $endTime
    } 

    return $_;
}

# Save the adjusted subtitles to a new file with UTF-8 encoding
$adjustedContent | Set-Content -LiteralPath $file -Encoding UTF8
