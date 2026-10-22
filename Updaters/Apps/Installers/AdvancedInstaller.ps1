[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Path,
    [Parameter(Mandatory)]
    [string]$Destination,
    [string[]]$Include,
    [string[]]$Exclude,
    [bool]$Flatten = $false,
    # Folders the MSI installs into the app folder itself (".:x64" in its Directory table), e.g. 'x64'
    [string[]]$Merge
)

# /extract runs the setup exe itself, so only run one with a valid signature
$signature = Get-AuthenticodeSignature -LiteralPath $Path;
if ($signature.Status -ne 'Valid') {
    Write-Host "[ERROR] $Path is not validly signed ($($signature.Status)), not running it." -ForegroundColor Red;
    return @{
        Success = $false
    }
}

$extractPath = "$env:TEMP\App_Updaters\AdvancedInstaller\$(Split-Path -Leaf $Path)";
if (Test-Path -LiteralPath $extractPath) {
    Remove-Item -LiteralPath $extractPath -Recurse -Force;
}
New-Item -ItemType Directory -Force $extractPath | Out-Null;

# Unpacks the MSI and the app files into a subfolder named after the package, e.g. 15E018F\
$extractProcess = Start-Process -FilePath $Path -ArgumentList @(
    "/extract",
    """$extractPath"""
) -WindowStyle Hidden -PassThru -Wait;
$sourcePath = (Get-ChildItem -LiteralPath $extractPath -Directory -ErrorAction SilentlyContinue | Select-Object -First 1).FullName;
if ($extractProcess.ExitCode -ne 0 -or !$sourcePath) {
    Write-Host "[ERROR] Advanced Installer extraction failed for $Path." -ForegroundColor Red;
    return @{
        Success = $false
    }
}

foreach ($folder in $Merge) {
    $mergePath = Join-Path $sourcePath $folder;
    if (!(Test-Path -LiteralPath $mergePath -PathType Container)) {
        Write-Host "[ERROR] No '$folder' folder inside $Path." -ForegroundColor Red;
        return @{
            Success = $false
        }
    }
    Copy-Item -Path "$mergePath\*" -Destination $sourcePath -Recurse -Force;
    Remove-Item -LiteralPath $mergePath -Recurse -Force;
}

# The MSI packages are the installer, not app files
Get-ChildItem -LiteralPath $sourcePath -Filter '*.msi' -File | Remove-Item -Force;

return & "$PSScriptRoot\_Copy.ps1" -Source $sourcePath `
    -Destination $Destination `
    -Include $Include `
    -Exclude $Exclude `
    -Flatten:$Flatten;
