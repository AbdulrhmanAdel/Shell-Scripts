$file = $null;
$delayMilliseconds = $null;
$startFromSecond = $null;
. Parse-Args.ps1 $args;

$delayTimeSpan = [timespan]::FromMilliseconds($delayMilliseconds)
Write-Output "Start Delaying By $delayTimeSpan $($delayTimeSpan.TotalMilliseconds), Start From $startFromSecond To File: $file";
#region Functions
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

function SerializeTimeSpan ($timeSpan) {
    return '{0:00}:{1:00}:{2:00},{3:000}' -f $timeSpan.Hours, $timeSpan.Minutes, $timeSpan.Seconds, $timeSpan.Milliseconds
}

function SerializeDialogue {
    param (
        $startTime,
        $endTime
    )
    
    return "$(SerializeTimeSpan -timeSpan $startTime) --> $(SerializeTimeSpan -timeSpan $endTime)";
}

$global:currenetSubIndex = 1;
function BuildFinalDialog {
    param (
        $startTime,
        $endTime,
        $content
    )

    $time = SerializeDialogue -startTime $startTime -endTime $endTime;
    $final = @($global:currenetSubIndex, $time) + $content;    
    $global:currenetSubIndex++;
    return $final;
}

#endregion
$content = Get-Content -LiteralPath $file -Encoding $encoding;
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

$dialogs | Sort-Object -Property StartTime | ForEach-Object {
    $dialog = $_;
    $startTime = $dialog.StartTime;
    $newStartTime = $startTime.Add($delayTimeSpan);
    if ($startFromSecond) {
        if ($startTime.TotalSeconds -lt $startFromSecond) {
            return BuildFinalDialog -startTime $dialog.StartTime `
                -endTime $dialog.EndTime `
                -content $dialog.Content;
        }

        if ($newStartTime.TotalSeconds -lt $startFromSecond) {
            return;
        }
    }
    
    if ($newStartTime.TotalMilliseconds -le 0) {
        return;
    }

    $endTime = $dialog.EndTime.Add($delayTimeSpan);
    return BuildFinalDialog -startTime  $newStartTime `
        -endTime $endTime `
        -content $dialog.Content;
} | Where-Object {
    $null -ne $_
} | Set-Content -LiteralPath $file -Encoding $encoding;