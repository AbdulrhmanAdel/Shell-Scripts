function ParseArgs {
    param ($list, [string]$key)
    $value = $list | Where-Object { $null -ne $_ -and $_.ToString().StartsWith("$key=") };
    if (!$value) { return $null; }
    return $value -replace "$key=", ""
}

$file = ParseArgs -list $args -key "file";
$delayMilliseconds = [double](ParseArgs -list $args -key "delayMilliseconds");
$startFromSecond = [double](ParseArgs -list $args -key "startFromSecond");

$delayTimeSpan = [timespan]::FromMilliseconds($delayMilliseconds);
Write-Output "Start Delaying By $delayTimeSpan $($delayTimeSpan.TotalMilliseconds), Start From $startFromSecond To File: $file";
#region Functions
function ParseTimeSpan {
    param (
        $time
    )
    
    return [timespan]::ParseExact($time, "h\:mm\:ss\.ff", $null)
}

function SerializeTimeSpan ($timeSpan) {
    return $timeSpan.ToString("hh\:mm\:ss\.ff");
}

function ParseDialogue {
    param (
        $dialogue
    )
    
    return "Dialogue: $($dialogue.Layer),$(SerializeTimeSpan($dialogue.StartTime)),$(SerializeTimeSpan($dialogue.EndTime)),$($dialogue.Style),$($dialogue.Name),$($dialogue.MarginL),$($dialogue.MarginR),$($dialogue.MarginV),$($dialogue.Effect),$($dialogue.Text)"
}

function SerializeDialogue {
    param ($line)
    return @{
        Layer           = $Matches["Layer"]
        StartTime       = ParseTimeSpan -time $Matches["StartTime"]
        EndTime         = ParseTimeSpan -time $Matches["EndTime"]
        Style           = $Matches["Style"]
        Name            = $Matches["Name"]
        MarginL         = $Matches["MarginL"]
        MarginR         = $Matches["MarginR"]
        MarginV         = $Matches["MarginV"]
        Effect          = $Matches["Effect"]
        Text            = $Matches["Text"]
        OriginalContent = $line
    }
}


function AddDialogue {
    param (
        $adjustedContent,
        $dialogue
    )
    $sub = ParseDialogue -dialogue $dialogue;
    $adjustedContent.Add($sub) | Out-Null;
}

function AddOriginalDialogue {
    param (
        $adjustedContent,
        $dialogue
    )

    $adjustedContent.Add($dialogue.OriginalContent) | Out-Null;
}

#endregion

$dialogues = New-Object System.Collections.Generic.List[System.Object];
$content = Get-Content -LiteralPath $file | ForEach-Object {
    if ($_ -match "Dialogue: (?<Layer>\d+),(?<StartTime>\d{1,2}:\d{2}:\d{2}\.\d{2}),(?<EndTime>\d{1,2}:\d{2}:\d{2}\.\d{2}),(?<Style>[^,]*),(?<Name>[^,]*),(?<MarginL>\d+),(?<MarginR>\d+),(?<MarginV>\d+),(?<Effect>[^,]*),(?<Text>.+)") {
        $dialogues.Add((SerializeDialogue -line $_)) | Out-Null | Out-Null;
    }
    else {
        return $_;
    }
}

$dialogues = $dialogues | Sort-Object -Property StartTime;
$adjustedContent = New-Object System.Collections.Generic.List[System.Object] -ArgumentList @($content.Count + $dialogues.Count);
$content | ForEach-Object {
    $adjustedContent.Add($_) | Out-Null;
    if ($_ -ne "[Events]") {
        return;
    }

    foreach ($dialogue in $dialogues) {
        $startTime = $dialogue.StartTime;
        $newStartTime = $startTime.Add($delayTimeSpan);
        if ($startFromSecond) {
            if ($startTime.TotalSeconds -lt $startFromSecond) {
                AddOriginalDialogue -adjustedContent $adjustedContent -dialogue $dialogue;
                continue;
            }

            if ($newStartTime.TotalSeconds -lt $startFromSecond) {
                continue;
            }
        }
    
        if ($newStartTime.TotalMilliseconds -le 0) {
            continue;
        }

        $dialogue.StartTime = $newStartTime;
        $dialogue.EndTime = $dialogue.EndTime.Add($delayTimeSpan);
        AddDialogue -adjustedContent $adjustedContent -dialogue $dialogue;
    }
}

$adjustedContent | Set-Content -LiteralPath $file; 