[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$File,
    [int]$DelayMilliseconds,
    [int]$StartFromSecond
)

$delayTimeSpan = [timespan]::FromMilliseconds($DelayMilliseconds);
Write-Output "Start Delaying By $delayTimeSpan $($delayTimeSpan.TotalMilliseconds), Start From $StartFromSecond To File: $file";
$assContent = Ass-Parser.ps1 -File $File -WithStyles;
$assContent.Content = $assContent.Content | ForEach-Object {
    $startTime = $_.StartTime;
    if ($StartFromSecond) {
        if ($startTime.TotalSeconds -lt $StartFromSecond) {
            return $_;
        }
    }
    
    $newStartTime = $startTime.Add($delayTimeSpan);
    if ($newStartTime.TotalMilliseconds -gt 0) {
        $_.StartTime = $newStartTime;
        $_.EndTime = $_.EndTime.Add($delayTimeSpan);
        return $_;
    }

};
& Ass-Assembler.ps1 -Dialogs $assContent -Encoding "UTF8" -OutputPath $File;
