$coursePath = $args[0];
$videos = Get-ChildItem -LiteralPath $coursePath -Filter "*.mp4" | ForEach-Object {
    $isMatch = $_.Name -match "lesson(\d+)\.mp4"
    if ($isMatch) {
        $lessonNumber = [int]$Matches[1];
        return @{
            Path      = $_.FullName
            Number    = $lessonNumber
            Extension = $_.Extension
        }
    }
} | Sort-Object -Property Number;

$outputPath = $coursePath + " (Fixed)";
if (!(Test-Path -LiteralPath $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory | Out-Null;
}

$currentIndex = 0;
$currentSectionPath = $null;
$sectionNumber = 1;
Get-Content -LiteralPath "$coursePath/index.txt" | ForEach-Object {
    $isEpisode = $_ -match "^\d+.*";
    if ($isEpisode) {
        $video = $videos[$currentIndex];
        $currentIndex++;
        $destination = $currentSectionPath + "/$($_)" + $video.Extension;
        Copy-Item -LiteralPath $video.Path -Destination $destination;
        return;
    }

    $currentSectionPath = "$outputPath/$sectionNumber- $($_)";
    $sectionNumber++;
    if (!(Test-Path -LiteralPath $currentSectionPath)) {
        New-Item -Path $currentSectionPath -ItemType Directory | Out-Null;
    }
};