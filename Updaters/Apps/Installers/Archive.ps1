[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path,
    $Destination,
    $Flatten = $false
)

$archiveProcess = Start-Process 7z -ArgumentList @(
    "x", 
    """$Path""",
    "-o$Destination"
) -NoNewWindow -PassThru -Wait;

$successArchive = !$archiveProcess -or $archiveProcess.ExitCode -gt 0
if (!$successArchive) {
    Write-Host "[ERROR] Archive extraction failed for $Path." -ForegroundColor Red;
    return @{
        Success = $false
    }
}

if ($Flatten) {
    $flattenProcess = & "$PSScriptRoot\_Flatten.ps1" -Path $Destination;
    if (!$flattenProcess.Success) {
        Write-Host "[ERROR] Flattening failed for $Destination." -ForegroundColor Red;
        return @{
            Success = $false
        }
    }
}

return @{
    Success = $true;
}