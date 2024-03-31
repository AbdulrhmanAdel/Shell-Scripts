function ParseArgs {
    param ($list, [string]$key)
    $value = $list | Where-Object { $null -ne $_ -and $_.StartsWith("$key=") };
    if (!$value) { return $null; }
    return $value -replace "$key=", ""
}

$file = ParseArgs -list $args -key "file";
$delayMilliseconds = [int](ParseArgs -list $args -key "delayMilliseconds");
$startFromSecond = [double](ParseArgs -list $args -key "startFromSecond");

$delayTimeSpan = [timespan]::FromMilliseconds($delayMilliseconds)
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
    param (
        $dialogue
    )
    
    $content.OriginalContent[0] = "$(SerializeTimeSpan -timeSpan $dialogue.StartTime) --> $(SerializeTimeSpan -timeSpan $dialogue.EndTime)";
    return $content.OriginalContent[0];
}

function SerializeDialogue {
    param ($line)
    return @{
        StartTime    = ParseTimeSpan -time $Matches["StartTime"]
        EndTime      = ParseTimeSpan -time $Matches["EndTime"]
        Text         = $Matches["Text"]
        OriginalLine = $line
    }
}


$currenetSubIndex = 1;
function AddDialogue {
    param (
        $adjustedContent,
        $dialogue
    )
    ParseDialogue -dialogue $dialogue;
    AddOriginalDialogue -adjustedContent $adjustedContent -dialogue $dialogue;
}

function AddOriginalDialogue {
    param (
        $adjustedContent,
        $dialogue
    )
    $adjustedContent.Add($currenetSubIndex) | Out-Null;
    $sub = $dialogue.OriginalContent;
    for ($i = 0; $i -lt $sub.Count; $i++) {
        $adjustedContent.Add($sub[$i]) | Out-Null;
    }
    $adjustedContent.Add("") | Out-Null;
    $currenetSubIndex++;
}

#endregion

$timeRegex = "(?<StartTime>\d+:\d+:\d+,\d+) --> (?<EndTime>\d+:\d+:\d+,\d+)"
$dialogues = New-Object System.Collections.Generic.List[System.Object];
$content = (Get-Content -LiteralPath $file);
for ($i = 0; $i -lt $text.Count; $i++) {
    if ($line -eq "") {
        continue;
    }
    

}

$adjustedContent = New-Object System.Collections.Generic.List[System.Object] -ArgumentList @($dialogues.Count * 3);
$dialogues | Sort-Object -Property StartTime | ForEach-Object {
    $dialogue = $_;
    $startTime = $dialogue.StartTime;
    $newStartTime = $startTime.Add($delayTimeSpan);
    if ($startFromSecond) {
        if ($startTime.TotalSeconds -lt $startFromSecond) {
            AddOriginalDialogue($adjustedContent, $dialogue);
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