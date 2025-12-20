param (
    [Parameter(Mandatory)] [string]$SubtitlePath,
    [Parameter(Mandatory)] [string]$SavePath,
    [string]$RenameTo,
    [string]$EpisodeRegex,
    [string]$QualityRegex
)

$subtitlePathInfo = Get-Item -LiteralPath $SubtitlePath -ErrorAction SilentlyContinue;
if (-not $subtitlePathInfo) {
    Write-Error "SubtitlePath '$SubtitlePath' does not exist."
    exit 1
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

    $finalName = $SubtitleFileInfo.BaseName
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
        Data    = $files
    }
}

if ($EpisodeRegex) {
    $files = @($files | Where-Object { $_.Name -match $EpisodeRegex })
}

if ($QualityRegex) {
    $primaryFile = $files | Where-Object { $_.Name -match $QualityRegex } | Select-Object -First 1
    if ($primaryFile) { $files = @($primaryFile) }
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