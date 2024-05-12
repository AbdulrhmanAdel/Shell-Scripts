$inputFiles = $args | Where-Object { (Get-Item -LiteralPath $_) -is [System.IO.FileInfo] };
if ($inputFiles.Length -le 0) { Exit; };
$subtitles = @($inputFiles | Where-Object {
        return $_.EndsWith(".ass") -or $_.EndsWith(".srt");
    })

$videos = @($inputFiles | Where-Object {
        return $_.EndsWith(".mkv") -or $_.EndsWith(".mp4");
    })

if ($subtitles.Length -eq 0 -or $subtitles.Length -ne $videos.Length) {
    Write-Host "Missmatch Numbers: Subtitles Count $($subtitles.Length), Videos Count $($videos.Length)" -ForegroundColor Red
    if ((Read-Host "Continue? Press 'N' to cancel And Any Key To Continue").ToUpper() -eq "N") {
        exit;
    }
}

$folderPath = (Get-Item -LiteralPath $videos[0]).DirectoryName;
$episodeNumberRegex = "(?i)(Episode|Ep|E|[-,|,_,*,#,\.]|\[| )(?<EpisodeNumber>\d+)([-,|,_,*,#,\.]| |\]|v\d+)";
function Get-EpisodeNumber($fileName) {
    $matched = $fileName -match $episodeNumberRegex;
    if (!$matched) {
        Write-Host "Can't Extract Episode Number From $fileName";
        return; 
    }
    $episodeNumber = [int]($Matches["EpisodeNumber"]);
    if (!$episodeNumber) {
        Write-Host "Can't Get EpisodeNumber for $fileName, GOT $episodeNumber"
        timeout 15
        exit;
    }

    return $episodeNumber;
}

$videos = $videos | Foreach-Object { return } {
    $fileName = (Get-Item -LiteralPath $_).Name;
    $obj = New-Object PSObject -Property @{
        FileName      = $fileName
        EpisodeNumber = Get-EpisodeNumber($fileName)
    }
    # Output the custom object
    return $obj
} | Sort-Object -Property EpisodeNumber;

$subtitles = $subtitles | Foreach-Object { return } {
    $fileName = (Get-Item -LiteralPath $_).Name;
    $obj = New-Object PSObject -Property @{
        FileName      = $fileName
        EpisodeNumber = Get-EpisodeNumber($fileName)
    }
    # Output the custom object
    return $obj
};
$isSomeEpisodeMissSubtitle = $false;
$dic = New-Object System.Collections.ArrayList;
foreach ($video in $videos) {
    $subtitle = $subtitles | Where-Object { $_.EpisodeNumber -eq $video.EpisodeNumber } | Select-Object -First 1
    if (!$subtitle) {
        $isSomeEpisodeMissSubtitle = $true;
        Write-Host "$($video.EpisodeNumber)-$($video.FileName) => Not-Sub found" -ForegroundColor Red
        continue;
    }

    Write-Host $video.EpisodeNumber -ForegroundColor Green -NoNewline;
    Write-Host "-$($video.FileName)" -NoNewline
    Write-Host " => " -NoNewline -ForegroundColor Blue;
    Write-Host $($subtitle.EpisodeNumber) -ForegroundColor Green -NoNewline;
    Write-Host "-$($subtitle.FileName)";
    $dic.Add($($video, $subtitle)) | Out-Null;
}

if ($isSomeEpisodeMissSubtitle) {
    timeout 15;
    exit;
}

$continue = & Prompt.ps1 -message "Do You Want To Continue?"
if (!$continue) {
    Write-Host "EXITING" -ForegroundColor Red
    Start-Sleep -Seconds 5;
    EXIT;
}

$replaceRegex = "(?i)-PSA|\(Hi10\)(_| )*|\[AniDL\] *";
foreach ($files in $dic) {
    $video = $files[0];
    $newVideoName = $video.FileName -replace $replaceRegex, "";
    Rename-Item -LiteralPath "$folderPath/$($video.FileName)" -NewName "$newVideoName";
    $subtitle = $files[1];
    $videoExt = [System.IO.Path]::GetExtension($newVideoName);
    $subtitleExt = [System.IO.Path]::GetExtension($subtitle.FileName);
    $newSubName = $newVideoName.Replace($videoExt, $subtitleExt);
    Rename-Item -LiteralPath "$folderPath/$($subtitle.FileName)" -NewName "$newSubName";
}

timeout 5;