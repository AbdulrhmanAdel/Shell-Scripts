param (
    [Parameter(Mandatory)] [string]$SubtitlePath,
    [Parameter(Mandatory)] [string]$SavePath,
    [string]$RenameTo,
    $Filter
)

$subtitlePathInfo = Get-Item -LiteralPath $SubtitlePath -ErrorAction SilentlyContinue;
if (-not $subtitlePathInfo) {
    Write-Error "SubtitlePath '$SubtitlePath' does not exist."
    return @{
        Success = $false
        Message = "SubtitlePath '$SubtitlePath' does not exist."
    }
}

$files = @($subtitlePathInfo);
try {
    $parent = Split-Path $SubtitlePath;
    $fileName = Split-Path -Leaf $SubtitlePath;
    $extractLocation = "$parent\$fileName-Files"
    & 7z x $SubtitlePath -aoa -bb0 -o"$extractLocation" | Out-Null;
    $files = @(Get-ChildItem -LiteralPath $extractLocation -Force -Include *.ass, *.srt, *.sub)
}
catch {
    Write-Error "Failed to extract SubtitlePath '$SubtitlePath'. $_"
}


function CopyFile {
    param (
        [System.IO.FileInfo]$File,
        [string]$Suffix
    )

    $finalName = $File.BaseName
    if ($RenameTo) { $finalName = $RenameTo }
    if ($Suffix) {
        $finalName += $Suffix;
    }
    if ($File.Attributes.HasFlag([System.IO.FileAttributes]::Hidden)) { $File.Attributes -= 'Hidden' }
    $dest = Join-Path -Path $SavePath -ChildPath "$finalName$($File.Extension)"
    Copy-Item -LiteralPath $File.FullName -Destination $dest -Force
}

if ($files.Count -eq 0) {
    Write-Warning "No subtitle files found in: $SubtitlePath"
    return @{
        Success = $false
        Message = "No subtitle files found in: $SubtitlePath"
    }
}

if ($files.Count -eq 1) {
    CopyFile -File $files[0];
    return @{
        Success = $true;
        Files   = $files
    }
}

if ($Filter) {
    $files = @($files | Where-Object { $Filter.Invoke($_.Name) })
}

$index = 0
foreach ($file in $files) {
    CopyFile -File $file -Suffix ".$index";
    $index++
}

return @{
    Success = $true
    Files   = $files
}
