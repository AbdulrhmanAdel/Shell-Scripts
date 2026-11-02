param(
    [string[]]$Paths,
    [Alias("Excludes")]
    [string[]]$Exclude
)

function IsExcluded {
    param(
        [string]$Name
    )
    foreach ($pattern in $Exclude) {
        if ($Name -match $pattern) {
            return $true
        }
    }
    return $false
}


$RemoveItem = $Exclude.Length ? {
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

    # -Force: Linux hides dotfiles, which would keep the folder from being emptied. Not on Windows, where it
    # would also delete the hidden desktop.ini of a folder icon
    Get-ChildItem -LiteralPath $DirectoryInfo.FullName -Force:$IsLinux | ForEach-Object {
        # A link to a folder is removed as a link: following it would delete what it points to
        if ($_ -is [System.IO.DirectoryInfo] -and !$_.LinkType) { 
            HandleDirectory -DirectoryInfo $_;
            return;
        }

        $RemoveItem.Invoke($_);
    }

    if (Get-ChildItem -LiteralPath $DirectoryInfo.FullName -Force:$IsLinux -ErrorAction SilentlyContinue) {
        return;
    }

    Remove-Item -LiteralPath $DirectoryInfo.FullName -Force
}

foreach ($item in $Paths) {
    $info = Get-Item -LiteralPath $item -ErrorAction SilentlyContinue
    if (-not $info) {
        Write-Host "[WARN] Could not get item info: $item" -ForegroundColor Red
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