[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$File
)

$encoding = & Get-FileEncoding.ps1 $File;
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

$content = Get-Content -LiteralPath $File -Encoding $encoding;
$timeRegex = "(?<StartTime>\d+:\d+:\d+,\d+) --> (?<EndTime>\d+:\d+:\d+,\d+)"
$times = @();
for ($i = 0; $i -lt $content.Count; $i++) {
    if ($content[$i] -match $timeRegex) {
        $times += @{
            StartTime  = ParseTimeSpan -time $Matches["StartTime"]
            EndTime    = ParseTimeSpan -time $Matches["EndTime"]
            LineNumber = $i
        }
    }
}

$dialogs = @();
for ($i = 0; $i -lt $times.Count - 1; $i++) {
    $start = $times[$i];
    $end = $times[$i + 1];
    $dialogs += [PSCustomObject]@{
        Content   = $content[$($start.LineNumber + 1)..$($end.LineNumber - 2)]
        StartTime = $start.StartTime
        EndTime   = $start.EndTime
    };
}

$lastLine = $times[$times.Length - 1];
$dialogs += [PSCustomObject]@{
    Content   = $content[$($lastLine.LineNumber + 1)..$content.Length]
    StartTime = $lastLine.StartTime
    EndTime   = $lastLine.EndTime
}

return $dialogs;