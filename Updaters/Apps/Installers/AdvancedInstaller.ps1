[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Path,
    [Parameter(Mandatory)]
    [string]$Destination,
    # Folders of the setup whose contents go straight into $Destination, e.g. "x64" for the 64-bit dlls
    [string[]]$Merge,
    # Files and folders of the setup to leave out, wildcards allowed
    [string[]]$Exclude
)

# Advanced Installer setups unpack themselves with /extract:"<folder>", without installing or asking for admin
$extractPath = "$env:TEMP\App_Updaters\AdvancedInstaller\$(Split-Path -Leaf $Path)";
if (Test-Path -LiteralPath $extractPath) {
    Remove-Item -LiteralPath $extractPath -Recurse -Force;
}
New-Item -ItemType Directory -Force $extractPath | Out-Null;
$setup = Start-Process -FilePath $Path -ArgumentList "/extract:""$extractPath""" -Wait -PassThru;
if ($setup.ExitCode -ne 0) {
    Write-Host "[ERROR] $Path /extract exited with code $($setup.ExitCode)." -ForegroundColor Red;
    return @{
        Success = $false
    }
}

# The files land in one folder with a generated name (e.g. 15E018F)
$root = Get-Item -LiteralPath $extractPath;
$items = @(Get-ChildItem -LiteralPath $root.FullName);
if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
    $root = $items[0];
}
if (!(Get-ChildItem -LiteralPath $root.FullName)) {
    Write-Host "[ERROR] $Path /extract unpacked nothing." -ForegroundColor Red;
    return @{
        Success = $false
    }
}

function Test-Excluded($name) { [bool]($Exclude | Where-Object { $name -like $_ }) }

New-Item -ItemType Directory -Force $Destination | Out-Null;
try {
    foreach ($item in Get-ChildItem -LiteralPath $root.FullName) {
        if (Test-Excluded $item.Name) {
            continue;
        }
        if ($item.PSIsContainer -and $Merge -contains $item.Name) {
            Get-ChildItem -LiteralPath $item.FullName | Where-Object { !(Test-Excluded $_.Name) } |
                Copy-Item -Destination $Destination -Recurse -Force -ErrorAction Stop;
            continue;
        }
        Copy-Item -LiteralPath $item.FullName -Destination $Destination -Recurse -Force -ErrorAction Stop;
    }
}
catch {
    Write-Host "[ERROR] Copying the setup's files failed: $_" -ForegroundColor Red;
    return @{
        Success = $false
    }
}
finally {
    Remove-Item -LiteralPath $extractPath -Recurse -Force -ErrorAction SilentlyContinue;
}

return @{
    Success = $true
}
