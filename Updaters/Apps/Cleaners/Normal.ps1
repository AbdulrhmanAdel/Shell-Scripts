# Delete all files and subdirectories in $Paths except those matching any regex in $Excludes.
# $Excludes is an array of regex patterns. Do not delete the top-level directories themselves.

param(
    [string[]]$Paths,
    [string[]]$Excludes
)

function IsExcluded {
    param(
        [string]$Name
    )
    foreach ($pattern in $Patterns) {
        if ($Name -match $pattern) {
            return $true
        }
    }
    return $false
}


$RemoveItem = $Excludes.Length ? {
    param (
        $Info
    )

    if (IsExcluded -Name $Info.Name) {
        Write-Host "[INFO] Excluded item: $($Info.FullName)" -ForegroundColor DarkGray
        return
    }

    Remove-Item -LiteralPath $Info.FullName -Force
    Write-Host "[INFO] Deleted: $($Info.FullName)" -ForegroundColor Yellow
} : {
    param (
        $Info
    )

    Remove-Item -LiteralPath $Info.FullName -Force
    Write-Host "[INFO] Deleted: $($Info.FullName)" -ForegroundColor Yellow
}


function HandleDirectory {
    param (
        $DirectoryInfo,
        $RemoveRoot = $false
    )

    if (IsExcluded -Name $DirectoryInfo.Name) {
        Write-Host "[INFO] Excluded directory: $($DirectoryInfo.FullName)" -ForegroundColor DarkGray
        return
    }

    Get-ChildItem -Path $DirectoryInfo.FullName | ForEach-Object {
        if ($_ -is [System.IO.DirectoryInfo]) { 
            HandleDirectory -DirectoryInfo $_;
            return;
        }

        $RemoveItem.Invoke($_);
    }

    Remove-Item -LiteralPath $DirectoryInfo.FullName -Force
}

foreach ($item in $Paths) {
    $info = Get-Item -LiteralPath $item -ErrorAction SilentlyContinue
    if (-not $info) {
        Write-Host "[WARN] Could not get item info: $fullPath" -ForegroundColor Red
        continue
    }

    if ($info.PSIsContainer) {
        HandleDirectory -DirectoryInfo $info;
    }
    elseif ($info -is [System.IO.FileInfo]) {
        $RemoveItem.Invoke($info);
    }
}

return @{
    Success = $true
}