Write-Output "$args";

$folderPath = $args[0];

$removeText = Read-Host "Do you want to remove any text from file names?";

$files = Get-ChildItem $folderPath -Force;

$videos = $files | Where-Object { $_.Name -like "*.mkv" -or $_.Name -like "*.mp4" } | Sort-Object -Property Name;
$subtitles = $files | Where-Object { $_.Name -like "*.srt" -or $_.Name -like "*.ass" } | Sort-Object -Property Name;
if ($videos.Length -ne $subtitles.Length) {
    Write-Output "Videos and subtitles count not equal";
    Read-Host "Press Any key To Exists";
}

for ($i = 0; $i -lt $videos.Length; $i++) {
    $video = $videos[$i];
    $subtitle = $subtitles[$i];

    Write-Output "$($video.Name): $($subtitle.Name)";
}

Read-Host "Continue?"

for ($i = 0; $i -lt $videos.Length; $i++) {
    $video = $videos[$i];
    $subtitle = $subtitles[$i];


    $videoName = $video.Name;
    if ($removeText) {
        $videoName = $videoName -replace $removeText;
        Rename-Item `
            -Path $video.FullName `
            -NewName $videoName;
    }

    $newName = $videoName -replace $video.Extension, $subtitle.Extension;
    Rename-Item `
        -Path $subtitle.FullName `
        -NewName $newName;
}
