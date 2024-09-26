[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$File,
    [Parameter(Mandatory)]
    [int]$DelayMilliseconds,
    [System.Nullable[int]]$StartFromSecond
)

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
        $_.StartTime = $newStartTime;
        $_.EndTime = $_.EndTime.Add($delayTimeSpan);
        return $_;
    }

} | Where-Object {
    return $null -ne $_
}

& Srt-Assembler.ps1 -Dialogs $content -OutputPath $file -Encoding "UTF8";