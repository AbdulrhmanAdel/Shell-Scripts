$inputFiles = $args[0] | Where-Object { (Get-Item -LiteralPath $_) -is [System.IO.FileInfo] };
if ($inputFiles.Length -le 0) { Exit; };
$subtitles = @($inputFiles | Where-Object {
        return $_.EndsWith(".ass") -or $_.EndsWith(".srt");
    })

$videos = @($inputFiles | Where-Object {
        return $_.EndsWith(".mkv") -or $_.EndsWith(".mp4");
    })

# if ($subtitles.Length -eq 0 -or $subtitles.Length -ne $videos.Length) {
#     Write-Host "Missmatch Numbers: Subtitles Count $($subtitles.Length), Videos Count $($videos.Length)" -ForegroundColor Red
#     if ((Read-Host "Continue? Press 'N' to cancel And Any Key To Continue").ToUpper() -eq "N") {
#         exit;
#     }
# }

$folderPath = (Get-Item -LiteralPath $videos[0]).DirectoryName;
$episodeNumberRegex = "(Episode|Ep|E|[-,|,_,*,#,\.]|\[| |\dx)(?<EpisodeNumber>\d+)([-,|,_,*,#,\.]| |\]|v\d+)";
function Get-EpisodeNumber($fileName) {
    $episodeNumber = $null;
    $matched = $fileName -match $episodeNumberRegex;
    if (!$matched) {
        $fileNameWithoutExt = $fileName -replace [System.IO.Path]::GetExtension($fileName), "";
        if ([int]::TryParse($fileNameWithoutExt, [ref]$episodeNumber)) {
            return $episodeNumber
        }
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
        EpisodeNumber = Get-EpisodeNumber -fileName $fileName
    }
    # Output the custom object
    return $obj
} | Sort-Object -Property EpisodeNumber;

$subtitles = $subtitles | Foreach-Object {
    $fileName = (Get-Item -LiteralPath $_).Name;
    $obj = New-Object PSObject -Property @{
        FileName      = $fileName
        EpisodeNumber = Get-EpisodeNumber -fileName $fileName
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
    $continue = & Prompt.ps1 -message "Do You Want To Continue?"
    if (!$continue) {
        Write-Host "EXITING" -ForegroundColor Red
        Start-Sleep -Seconds 5;
        EXIT;
    }
}



$replaceRegex = "(?i)-PSA|(\(|\[)(Hi10|AniDL)(\)|\])(_| |-)*";
$signsRegex = "_"
# $renameSource = & Options-Selector.ps1 -options @("Subtitles", "Videos") -title "Rename Source" -defaultValue "Videos";
$renameSource = "Videos";
foreach ($files in $dic) {
    $source = $null;
    $target = $null;
    if ($renameSource -eq "Subtitles") { 
        $source = $files[1];
        $target = $files[0];
    }
    else {
        $source = $files[0];
        $target = $files[1];
    }

    $newSourceName = $source.FileName -replace $replaceRegex, "" -replace $signsRegex, " ";
    Rename-Item -LiteralPath "$folderPath/$($source.FileName)" -NewName "$newSourceName";
    $sourceExt = [System.IO.Path]::GetExtension($newSourceName);
    $targetExt = [System.IO.Path]::GetExtension($target.FileName);
    $newSubName = $newSourceName.Replace($sourceExt, $targetExt);
    Rename-Item -LiteralPath "$folderPath/$($target.FileName)" -NewName "$newSubName";
}

timeout 5;