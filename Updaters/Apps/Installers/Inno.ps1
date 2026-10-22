[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Path,
    [Parameter(Mandatory)]
    [string]$Destination,
    [string[]]$Include,
    [string[]]$Exclude,
    [bool]$Flatten = $false,
    [string]$SubPath = '{app}'
)

$extractPath = "$env:TEMP\App_Updaters\Inno\$(Split-Path -Leaf $Path)";
if (Test-Path -LiteralPath $extractPath) {
    Remove-Item -LiteralPath $extractPath -Recurse -Force;
}

$unpackProcess = Start-Process innounp -ArgumentList @(
    "-x",
    "-b",
    "-y",
    "-q",
    "-d""$extractPath""",
    """$Path"""
) -NoNewWindow -PassThru -Wait;
$sourcePath = Join-Path $extractPath $SubPath;
if ($unpackProcess.ExitCode -ne 0 -or !(Test-Path -LiteralPath $sourcePath)) {
    Write-Host "[ERROR] Inno Setup extraction failed for $Path." -ForegroundColor Red;
    return @{
        Success = $false
    }
}

return & "$PSScriptRoot\_Copy.ps1" -Source $sourcePath `
    -Destination $Destination `
    -Include $Include `
    -Exclude $Exclude `
    -Flatten:$Flatten;
