$file = $args[1];
$delayMilliseconds = $args[2];

function Adjust-Time {
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


$content = Get-Content -LiteralPath $file;
# Adjust the timestamps in the file
$adjustedContent = $content | ForEach-Object {
    if ($_ -match "Dialogue: (\d+),(\d+:\d\d:\d\d\.\d\d),(\d+:\d\d:\d\d\.\d\d),") {
        $originalStartTime = $Matches[2];
        $startTime = Adjust-Time -time $originalStartTime -delay $delayMilliseconds;
        $originalEndTime = $Matches[3];
        $endTime = Adjust-Time -time $originalEndTime  -delay $delayMilliseconds
        return $_ -replace $originalStartTime, $startTime -replace $originalEndTime, $endTime
    }
    
    return $_
}
        
# Save the adjusted subtitles to a new file
$adjustedContent | Set-Content -LiteralPath $file -Encoding UTF8;
