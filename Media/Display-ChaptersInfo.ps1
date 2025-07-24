[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments)]
    [string[]]
    $Files
)

$Files | Where-Object { $_ -match ".*(.mkv)$" }  | ForEach-Object {
    Write-Host "===================================" -ForegroundColor Red;
    $fileName = [System.IO.Path]::GetFileName($_);
    Write-Host "Info For $fileName" -ForegroundColor Green;
    $path = $_;

    Write-Host "Chapters" -ForegroundColor Green;
    $chapters = Get-Chapters.ps1 -FilePath $path;
    $chapters | ForEach-Object {
        Write-Host "======================" -ForegroundColor Cyan;
        Write-Host "Title: $($_.Title)";
        Write-Host "Start: $($_.Start)";
        Write-Host "End: $($_.End)";
        Write-Host "Duration: $($_.Duration)";
        Write-Host "SegmentId: $($_.SegmentId ?? 'N/A')";
        Write-Host "Hidden: $(!!$_.Hidden)";
    }
    Write-Host "";
    Write-Host "Streams" -ForegroundColor Gray;
    Write-Host "===================================" -ForegroundColor Red;
}
& Force-ManuallyExit.ps1;