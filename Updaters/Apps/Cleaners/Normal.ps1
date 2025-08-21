# Delete all files and subdirectories in $Paths except those matching any regex in $Excludes.
# $Excludes is an array of regex patterns. Do not delete the top-level directories themselves.

param(
    [string[]]$Paths,
    [string[]]$Excludes
)

function Is-Excluded {
    param(
        [string]$ItemPath,
        [string[]]$Patterns
    )
    foreach ($pattern in $Patterns) {
        if ($ItemPath -match $pattern) {
            return $true
        }
    }
    return $false
}


foreach ($item in $Paths) {
    $info = Get-Item -LiteralPath $fullPath -ErrorAction SilentlyContinue
    if (-not $info) {
        Write-Host "[WARN] Could not get item info: $fullPath" -ForegroundColor Red
        continue
    }
    if ($info.PSIsContainer) {
        Get-ChildItem -Path $fullPath -File -Recurse | ForEach-Object {
            if (-not (Is-Excluded -ItemPath $_.FullName -Patterns $Excludes)) {
                Write-Host "[INFO] Deleting file: $($_.FullName)" -ForegroundColor Yellow
                Remove-Item -LiteralPath $_.FullName -Force
            }
            else {
                Write-Host "[INFO] Excluded file: $($_.FullName)" -ForegroundColor DarkGray
            }
        }
        # Remove subdirectories (not the root dir)
        Get-ChildItem -Path $fullPath -Directory -Recurse | Sort-Object -Property FullName -Descending | ForEach-Object {
            if (-not (Is-Excluded -ItemPath $_.FullName -Patterns $Excludes)) {
                Write-Host "[INFO] Deleting directory: $($_.FullName)" -ForegroundColor Yellow
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
            else {
                Write-Host "[INFO] Excluded directory: $($_.FullName)" -ForegroundColor DarkGray
            }
        }
    }
    elseif ($info -is [System.IO.FileInfo]) {
        # File: delete if not excluded
        if (-not (Is-Excluded -ItemPath $fullPath -Patterns $Excludes)) {
            Write-Host "[INFO] Deleting file: $fullPath" -ForegroundColor Yellow
            Remove-Item -LiteralPath $fullPath -Force
        }
        else {
            Write-Host "[INFO] Excluded file: $fullPath" -ForegroundColor DarkGray
        }
    }
}
