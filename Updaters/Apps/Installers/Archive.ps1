[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path,
    $Destination
)

$archiveProcess = Start-Process 7z -ArgumentList @(
    "x", 
    """$Path""",
    "-o$Destination"
) -NoNewWindow -PassThru -Wait;

return @{
    Success = !$archiveProcess -or $archiveProcess.ExitCode -gt 0
}