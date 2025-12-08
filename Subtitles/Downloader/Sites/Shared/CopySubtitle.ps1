param (
    [Parameter(Mandatory=$true)][string]$SubtitlePath,
    [string]$SavePath,
    [string]$RenameTo,
    [string]$EpisodeRegex,
    [string]$QualityRegex
)

# Copy subtitle files from an extracted subtitle folder to the desired save path.
if (-not (Test-Path -LiteralPath $SubtitlePath)) {
    Write-Error "SubtitlePath '$SubtitlePath' does not exist."
    exit 1
}

$files = @(Get-ChildItem -LiteralPath $SubtitlePath -Force -Include *.ass, *.srt, *.sub)
if ($files.Count -eq 0) {
    Write-Warning "No subtitle files found in: $SubtitlePath"
    return @()
}

if ($EpisodeRegex -and $files.Length -gt 1) {
    $files = @($files | Where-Object { $_.Name -match $EpisodeRegex })
}

if ($QualityRegex -and $files.Length -gt 1) {
    $primaryFile = $files | Where-Object { $_.Name -match $QualityRegex } | Select-Object -First 1
    if ($primaryFile) { $files = @($primaryFile) }
}

if (-not $SavePath) {
    Write-Output $files.FullName
    return $files.FullName
}

if (-not (Test-Path -LiteralPath $SavePath)) { New-Item -ItemType Directory -Path $SavePath | Out-Null }

$copied = @()
$index = 0
foreach ($file in $files) {
    $finalName = $file.BaseName
    if ($RenameTo) { $finalName = $RenameTo }
    if ($files.Count -gt 1) {
        if ($index -gt 0) { $finalName += ".$index" }
        $index++
    }
    if ($file.Attributes.HasFlag([System.IO.FileAttributes]::Hidden)) { $file.Attributes -= 'Hidden' }

    $dest = Join-Path -Path $SavePath -ChildPath "$finalName$($file.Extension)"
    Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
    $copied += $dest
}

Write-Output $copied
