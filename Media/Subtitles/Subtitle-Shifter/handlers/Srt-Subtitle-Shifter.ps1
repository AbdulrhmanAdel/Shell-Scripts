$file = $null;
$delayMilliseconds = $null;
$startFromSecond = $null;
& Parse-Args.ps1 $args;

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

function ParseDialogue {
    param ($line)
    return @{
        StartTime       = ParseTimeSpan -time $Matches["StartTime"]
        EndTime         = ParseTimeSpan -time $Matches["EndTime"]
        OriginalContent = $line
    }
    
}

function SerializeDialogue {
    param (
        $dialogue
    )
    
    $dialogue.OriginalContent[0] = "$(SerializeTimeSpan -timeSpan $dialogue.StartTime) --> $(SerializeTimeSpan -timeSpan $dialogue.EndTime)";
    return $dialogue;
}

function AddDialogue {
    param (
        $adjustedContent,
        $dialogue
    )
    $dialogue = SerializeDialogue -dialogue $dialogue;
    AddOriginalDialogue -adjustedContent $adjustedContent -dialogue $dialogue;
}


$global:currenetSubIndex = 1;
function AddOriginalDialogue {
    param (
        $adjustedContent,
        $dialogue
    )
    $adjustedContent.Add($global:currenetSubIndex) | Out-Null;
    $sub = $dialogue.OriginalContent;
    for ($i = 0; $i -lt $sub.Count; $i++) {
        $adjustedContent.Add($sub[$i]) | Out-Null;
    }
    $adjustedContent.Add("") | Out-Null;
    $global:currenetSubIndex += 1; ;
}

#endregion

$timeRegex = "(?<StartTime>\d+:\d+:\d+,\d+) --> (?<EndTime>\d+:\d+:\d+,\d+)"
$dialogues = New-Object System.Collections.Generic.List[System.Object];
$content = (Get-Content -LiteralPath $file);
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

$adjustedContent = New-Object System.Collections.Generic.List[System.Object] -ArgumentList @($dialogues.Count * 3);
$dialogues | Sort-Object -Property StartTime | ForEach-Object {
    $dialogue = $_;
    $startTime = $dialogue.StartTime;
    $newStartTime = $startTime.Add($delayTimeSpan);
    if ($startFromSecond) {
        if ($startTime.TotalSeconds -lt $startFromSecond) {
            AddOriginalDialogue -adjustedContent $adjustedContent -dialogue $dialogue;
            return;
        }

        if ($newStartTime.TotalSeconds -lt $startFromSecond) {
            return;
        }
    }
    
    if ($newStartTime.TotalMilliseconds -le 0) {
        return;
    }

    $dialogue.StartTime = $newStartTime;
    $dialogue.EndTime = $dialogue.EndTime.Add($delayTimeSpan);
    AddDialogue -adjustedContent $adjustedContent -dialogue $dialogue;
}

$adjustedContent | Set-Content -LiteralPath $file; 