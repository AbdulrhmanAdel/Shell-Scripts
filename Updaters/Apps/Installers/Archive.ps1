[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Path,
    [Parameter(Mandatory)]
    [string]$Destination,
    [string[]]$Include,
    [string[]]$Exclude,
    [bool]$Flatten = $false,
    # An archive inside the archive to unpack instead, e.g. electron-builder portables: '$PLUGINSDIR\app-64.7z'
    [string]$InnerArchive,
    # Only install this folder of the archive, wildcards allowed, e.g. 'podman-*\usr\bin'
    [string]$SubPath
)

function Expand-Archive7z {
    param ([string]$Archive, [string]$Target)

    # A leftover extract from an earlier run would mix old files in (and make 7z ask to overwrite)
    if (Test-Path -LiteralPath $Target) {
        Remove-Item -LiteralPath $Target -Recurse -Force;
    }
    $archiveProcess = Start-Process 7z -ArgumentList @(
        "x",
        """$Archive""",
        "-o""$Target""",
        "-y"
    ) -NoNewWindow -PassThru -Wait;
    return $archiveProcess.ExitCode -eq 0;
}

$fileName = Split-Path -Leaf $Path;
$extractPath = "$env:TEMP\App_Updaters\Archive\$fileName"
if (!(Expand-Archive7z -Archive $Path -Target $extractPath)) {
    Write-Host "[ERROR] Archive extraction failed for $Path." -ForegroundColor Red;
    return @{
        Success = $false
    }
}

if ($InnerArchive) {
    $inner = Get-Item -Path (Join-Path $extractPath $InnerArchive) -ErrorAction SilentlyContinue | Select-Object -First 1;
    if (!$inner) {
        Write-Host "[ERROR] No '$InnerArchive' inside $Path." -ForegroundColor Red;
        return @{
            Success = $false
        }
    }
    $extractPath = "$extractPath.inner";
    if (!(Expand-Archive7z -Archive $inner.FullName -Target $extractPath)) {
        Write-Host "[ERROR] Archive extraction failed for $($inner.FullName)." -ForegroundColor Red;
        return @{
            Success = $false
        }
    }
}

if ($SubPath) {
    $sub = Get-Item -Path (Join-Path $extractPath $SubPath) -ErrorAction SilentlyContinue | Where-Object PSIsContainer | Select-Object -First 1;
    if (!$sub) {
        Write-Host "[ERROR] No '$SubPath' folder inside $Path." -ForegroundColor Red;
        return @{
            Success = $false
        }
    }
    $extractPath = $sub.FullName;
}

return & "$PSScriptRoot\_Copy.ps1" -Source $extractPath `
    -Destination $Destination `
    -Include $Include `
    -Exclude $Exclude `
    -Flatten:$Flatten;
