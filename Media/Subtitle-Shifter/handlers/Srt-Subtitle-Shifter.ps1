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
    $timeSpan = New-Object TimeSpan -ArgumentList $hours, $minutes, $seconds, $milliseconds
    # Convert delay from milliseconds to TimeSpan
    $delayTimeSpan = [timespan]::FromMilliseconds($delay)
    # Adjust the time
    $newTimeSpan = $timeSpan.Add($delayTimeSpan)
    # Format the new time back to string
    return '{0:00}:{1:00}:{2:00},{3:000}' -f $newTimeSpan.Hours, $newTimeSpan.Minutes, $newTimeSpan.Seconds, $newTimeSpan.Milliseconds
}

# Ensure UTF-8 encoding without BOM
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False

# Read the original subtitle file with UTF-8 encoding
$content = Get-Content -LiteralPath $file -Encoding UTF8

# Adjust the timestamps in the file
$adjustedContent = $content | ForEach-Object {
    if ($_ -match "(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})") {
        $startTime = Adjust-Time -time $Matches[1] -delay $delayMilliseconds
        $endTime = Adjust-Time -time $Matches[2] -delay $delayMilliseconds
        $_ -replace $Matches[1], $startTime -replace $Matches[2], $endTime
    } else {
        $_
    }
}

# Save the adjusted subtitles to a new file with UTF-8 encoding
$adjustedContent | Set-Content -LiteralPath $file -Encoding UTF8
