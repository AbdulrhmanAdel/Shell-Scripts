[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    $Dialogs,
    [Parameter(Mandatory)]
    [string]$outputPath,
    [Parameter(Mandatory)]
    [string]$encoding
)

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

$global:currenetSubIndex = 1;

$dialogs ??= $args[0];
$outputPath ??= $args[1];
$encoding ??= "UTF8"
$dialogs | ForEach-Object {
    return BuildFinalDialog -startTime  $_.StartTime `
        -endTime $_.EndTime `
        -content $_.Content;
} | Where-Object {
    $null -ne $_
} | Set-Content -LiteralPath $outputPath -Encoding $encoding;

