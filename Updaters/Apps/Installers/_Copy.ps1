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

if (!$Flatten -and !$Include.Length -and !$Exclude.Length) {
    Copy-Item -Path "$extractPath\*" -Destination $Destination -Force;
    return @{
        Success = $true;
    }
}


try {
    Get-ChildItem -Path $extractPath | Where-Object {
        if ($Include.Length) {
            return $_.Name -in $Include
        }

        if ($Exclude.Length) {
            return $_.Name -notin $Exclude
        }

        return $true
    } | ForEach-Object {
        if ($_ -is [System.IO.DirectoryInfo]) {
            Copy-Item -Path "$($_.FullName)\*" -Recurse -Destination $Destination -Force;
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