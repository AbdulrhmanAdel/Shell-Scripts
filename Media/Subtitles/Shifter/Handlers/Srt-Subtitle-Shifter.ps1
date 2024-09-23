$file = $null;
$delayMilliseconds = $null;
$startFromSecond = $null;
. Parse-Args.ps1 $args;
$delayTimeSpan = [timespan]::FromMilliseconds($delayMilliseconds)
Write-Output "Start Delaying By $delayTimeSpan $($delayTimeSpan.TotalMilliseconds), Start From $startFromSecond To File: $file";
$content = & Srt-Parser.ps1 -File $file;
$content = $content | ForEach-Object {
    $startTime = $_.StartTime;
    if ($startFromSecond) {
        if ($startTime.TotalSeconds -lt $startFromSecond) {
            return $_;
        }
    }
    
    $newStartTime = $startTime.Add($delayTimeSpan);
    if ($newStartTime.TotalMilliseconds -gt 0) {
        $_.EndTime = $_.EndTime.Add($delayTimeSpan);
        return $_;
    }

} | ForEach-Object {
    return $null -ne $_
}

& Srt-Assembler.ps1 -File $file -Encoding $encoding;