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
# A leftover extract from an earlier run would mix old files in (and make 7z ask to overwrite)
if (Test-Path -LiteralPath $extractPath) {
    Remove-Item -LiteralPath $extractPath -Recurse -Force;
}
$archiveProcess = Start-Process 7z -ArgumentList @(
    "x",
    """$Path""",
    "-o""$extractPath""",
    "-y"
) -NoNewWindow -PassThru -Wait;

if ($archiveProcess.ExitCode -ne 0) {
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
