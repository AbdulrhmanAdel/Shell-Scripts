[CmdletBinding()]
param (
    $Source,
    $Destination,
    $Include,
    $Exclude,
    $Flatten = $false
)

# Copy-Item skips dotfiles and turns symlinks into copies on Linux; cp -a keeps both, and the executable bits
function Copy-Entry {
    param ([string]$Path, [string]$Target)

    if ($IsLinux) {
        & cp -a -- $Path $Target;
        if ($LASTEXITCODE -ne 0) {
            throw "Could not copy $Path";
        }
        return;
    }
    Copy-Item -Path $Path -Destination $Target -Force -Recurse;
}

if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -Path $Destination -ItemType Directory -Force | Out-Null;
}

# A single downloaded file (e.g. yt-dlp.exe), "$Source\*" would match nothing
if (Test-Path -LiteralPath $Source -PathType Leaf) {
    Copy-Item -LiteralPath $Source -Destination $Destination -Force;
    return @{
        Success = $?;
    }
}

if ($IsLinux -and !$Flatten -and !$Include.Length -and !$Exclude.Length) {
    & cp -a -- "$Source/." $Destination;
    return @{
        Success = $LASTEXITCODE -eq 0;
    }
}

if (!$Flatten -and !$Include.Length -and !$Exclude.Length) {
    Copy-Item -Path "$Source\*" -Destination $Destination -Force -Recurse;
    return @{
        Success = $true;
    }
}


try {
    Get-ChildItem -LiteralPath $Source -Force:$IsLinux | Where-Object {
        if ($Include.Length) {
            return $_.Name -in $Include
        }

        if ($Exclude.Length) {
            return $_.Name -notin $Exclude
        }

        return $true
    } | ForEach-Object {
        # Flatten unwraps a folder into the destination (e.g. a zip's wrapper folder); otherwise it stays a folder
        if ($Flatten -and $_ -is [System.IO.DirectoryInfo]) {
            if ($IsLinux) {
                Copy-Entry -Path "$($_.FullName)/." -Target $Destination;
                return;
            }
            Copy-Entry -Path "$($_.FullName)\*" -Target $Destination;
            return;
        }
        Copy-Entry -Path $_.FullName -Target $Destination;
    }
}
catch {
    return @{
        Success = $false;
    }
}
return @{
    Success = $true;
}