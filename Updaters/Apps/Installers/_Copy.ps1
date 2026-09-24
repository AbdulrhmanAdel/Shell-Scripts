[CmdletBinding()]
param (
    $Source,
    $Destination,
    $Include,
    $Exclude,
    $Flatten = $false
)

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

if (!$Flatten -and !$Include.Length -and !$Exclude.Length) {
    Copy-Item -Path "$Source\*" -Destination $Destination -Force -Recurse;
    return @{
        Success = $true;
    }
}


try {
    Get-ChildItem -Path $Source | Where-Object {
        if ($Include.Length) {
            return $_.Name -in $Include
        }

        if ($Exclude.Length) {
            return $_.Name -notin $Exclude
        }

        return $true
    } | ForEach-Object {
        if ($_ -is [System.IO.DirectoryInfo]) {
            Copy-Item -Path "$($_.FullName)\*"  -Destination $Destination -Force -Recurse;
            return;
        }
        Copy-Item -Path $_.FullName -Destination $Destination -Force;
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