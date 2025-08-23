[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Path,
    [Parameter(Mandatory)]
    [string]$Destination,
    [string[]]$Include,
    [string[]]$Exclude,
    [bool]$Flatten = $false
)

$fileName = Split-Path -Leaf $Path;
$extractPath = "$env:TEMP\App_Updaters\Archive\$fileName"
$archiveProcess = Start-Process 7z -ArgumentList @(
    "x", 
    """$Path""",
    "-o$extractPath"
) -NoNewWindow -PassThru -Wait;

$successArchive = $archiveProcess -or $archiveProcess.ExitCode -eq 0
if (!$successArchive) {
    Write-Host "[ERROR] Archive extraction failed for $Path." -ForegroundColor Red;
    return @{
        Success = $false
    }
}

return & "$PSScriptRoot\_Copy.ps1" -Source $extractPath `
    -Destination $Destination `
    -Include $Include `
    -Exclude $Exclude `
    -Flatten:$Flatten;
