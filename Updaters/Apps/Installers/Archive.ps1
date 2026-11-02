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
    [string]$SubPath,
    # Files the archive ships under another name, renamed before installing, e.g. @{ 'RTSSHooks.dll.copy' = 'RTSSHooks.dll' }
    [hashtable]$Rename
)

function Expand-Archive7z {
    param ([string]$Archive, [string]$Target)

    # A leftover extract from an earlier run would mix old files in (and make 7z ask to overwrite)
    if (Test-Path -LiteralPath $Target) {
        Remove-Item -LiteralPath $Target -Recurse -Force;
    }
    # 7z only unpacks the .gz of a .tar.gz, and tar keeps the executable bits
    if ($IsLinux -and $Archive -match '\.(tar(\.\w+)?|tgz|txz|tbz2?)$') {
        New-Item -ItemType Directory -Force $Target | Out-Null;
        & tar -xf $Archive -C $Target;
        return $LASTEXITCODE -eq 0;
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
$extractRoot = "$(($env:TEMP ?? [IO.Path]::GetTempPath()).TrimEnd('\', '/'))/App_Updaters/Archive/$fileName";
$extractPath = $extractRoot;
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

# Not @($Rename.Keys): with no -Rename that is @($null), one pass with a null name
foreach ($name in $Rename.Keys) {
    $file = Join-Path $extractPath $name;
    if (!(Test-Path -LiteralPath $file)) {
        Write-Host "[ERROR] No '$name' inside $Path to rename." -ForegroundColor Red;
        return @{
            Success = $false
        }
    }
    Move-Item -LiteralPath $file -Destination (Join-Path $extractPath $Rename[$name]) -Force;
}

$result = & "$PSScriptRoot/_Copy.ps1" -Source $extractPath `
    -Destination $Destination `
    -Include $Include `
    -Exclude $Exclude `
    -Flatten:$Flatten;

# On Linux the temp folder is in RAM until the next reboot
foreach ($folder in $extractRoot, "$extractRoot.inner") {
    Remove-Item -LiteralPath $folder -Recurse -Force -ErrorAction SilentlyContinue;
}
return $result;
