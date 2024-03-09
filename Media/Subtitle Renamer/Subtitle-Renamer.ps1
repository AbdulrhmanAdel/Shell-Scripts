$inputFiles = $args;
if ($inputFiles.Length -le 0) { Exit; };
$subtitles = $inputFiles | Where-Object {
    return $_.EndsWith(".ass") -or $_.EndsWith(".srt");
}

$videos = $inputFiles | Where-Object {
    return $_.EndsWith(".mkv") -or $_.EndsWith(".mp4");
}

if ($subtitles.Length -eq 0 -or $subtitles.Length -ne $videos.Length) {
    Read-Host "subtitles $($subtitles.Length), videos $($videos.Length)"
    Exit;
}
$folderPath = (Get-Item -LiteralPath $videos[0]).DirectoryName;
function Get-EpisodeNumber($fileName) {
    $match = $fileName -match "(?i:(Episode *(\d+))|(E(\d+))|(E *(\d+))|(E *\((\d+)\)))|(-(\d+))|(- *(\d+))";
    $outNumber = $null;
    foreach ($match in $Matches.Values) {
        if ([Int32]::TryParse($match, [ref] $outNumber)) {
            break;
        }
    }

    return $outNumber;
}
$videos = $videos | Foreach-Object { return } {
    $fileName = (Get-Item -LiteralPath $_).Name;
    $obj = New-Object PSObject -Property @{
        FileName      = $fileName
        EpisodeNumber = Get-EpisodeNumber($_)
    }
    # Output the custom object
    return $obj
} | Sort-Object -Property EpisodeNumber;

$subtitles = $subtitles | Foreach-Object { return } {
    $fileName = (Get-Item -LiteralPath $_).Name;
    $obj = New-Object PSObject -Property @{
        FileName      = $fileName
        EpisodeNumber = Get-EpisodeNumber($_)
    }
    # Output the custom object
    return $obj
};

$dic = New-Object System.Collections.ArrayList;
foreach ($video in $videos) {
    $subtitle = $subtitles | Where-Object { $_.EpisodeNumber -eq $video.EpisodeNumber } | Select-Object -First 1
    Write-Host "$($video.EpisodeNumber)-$($video.FileName) => $($subtitle.EpisodeNumber)-$($subtitle.FileName)"
    $dic.Add($($video, $subtitle)) | Out-Null;
}

function PromptForYes {
    $result = (Read-Host "Press Y to continue or exit the window to stop").ToLower();
    if ($result -ne "y") { PromptForYes }
}
PromptForYes

function Remove-Text($text) {
    $text = $text.Replace("-PSA", "");
    $text = $text.Replace("(Hi10)", "");
    return $text;
}
foreach ($files in $dic) {
    $video = $files[0];
    $newVideoName = Remove-Text($video.FileName);
    Rename-Item -LiteralPath "$folderPath/$($video.FileName)" -NewName "$newVideoName";
    $subtitle = $files[1];
    $videoExt = [System.IO.Path]::GetExtension($newVideoName);
    $subtitleExt = [System.IO.Path]::GetExtension($subtitle.FileName);
    $newSubName = $newVideoName.Replace($videoExt, $subtitleExt);
    Rename-Item -LiteralPath "$folderPath/$($subtitle.FileName)" -NewName "$newSubName";
}

timeout 5;