[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [int]$Seconds = 5,
    [switch]$NoBreak
)

if ([Console]::IsInputRedirected) {
    Start-Sleep -Seconds $Seconds;
    return;
}

for ($left = $Seconds; $left -gt 0; $left--) {
    Write-Host "`rWaiting for $left seconds$($NoBreak ? '' : ', press a key to continue') " -NoNewline;
    for ($tick = 0; $tick -lt 10; $tick++) {
        if (!$NoBreak -and [Console]::KeyAvailable) {
            [Console]::ReadKey($true) | Out-Null;
            Write-Host;
            return;
        }
        Start-Sleep -Milliseconds 100;
    }
}
Write-Host;
