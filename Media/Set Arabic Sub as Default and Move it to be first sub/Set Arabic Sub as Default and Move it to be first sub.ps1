$mkvmerge = "D:\Programs\Media\Tools\mkvtoolnix\mkvmerge.exe";
$mediaInfo = "D:\Programs\Media\Tools\MediaInfo\MediaInfo.exe";
$inputPath = $args[0];
$videoType = $args[1];
$prefix = $null;

# $removeSent = Read-Host "Do you want to remove any char from video file?";
$removeSent = "-PSA";
switch ($videoType) {
    "Anime" { $prefix = "D:\Watch\Anime"; break; }
    "Movie" { $prefix = "D:\Watch\Movies"; break; }
    "Series" { $prefix = "D:\Watch\Series"; break; }
}

function GetIds($filePath) {
    $enLangId = 0;
    $arLangId = 0;
    $nonEnglishAudioId = 0;
    $englishAudioId = 0;
    $json = &$mediaInfo  --Output=JSON "$filePath" | ConvertFrom-Json;
    foreach ($track in $json.media.track) {
        $trackType = $track.'@type';

        switch ($trackType) {
            'Text' {  
                if ($track.Language -eq "en" -or $track.Language -eq "eng" -or $track.Title -eq "English") {
                    $enLangId = [int]$track.ID - 1;
                }
    
                if ($track.Language -eq "ara" -or $track.Language -eq "ar" -or $track.Title -contains "Arabic") {
                    $arLangId = [int]$track.ID - 1;
                }
            }
            'Audio' {
                if ($track.Language -eq "en" -or $track.Language -eq "eng" -or $track.Title -eq "English") {
                    $englishAudioId = [int]$track.ID - 1;
                }
                else {
                    $nonEnglishAudioId = [int]$track.ID - 1;
                }
            }
            Default {}
        }
    }

    if (!$nonEnglishAudioId) {
        $nonEnglishAudioId = $englishAudioId;
    }

    return $enLangId, $arLangId, $nonEnglishAudioId;
}

function Start-Convert-Video($inputPath, $outputPath, $enLangId, $arLangId, $audio) {

    &$mkvmerge `
        --output "$outputPath" `
        --audio-tracks "$audio" `
        --subtitle-tracks "$enLangId,$arLangId" `
        --default-track-flag "$($arLangId):yes" `
        --forced-display-flag "$($audio):yes" `
        --default-track-flag "$($audio):yes" `
        --forced-display-flag "$($arLangId):yes" `
        "$inputPath" `
        --track-order "0:0,0:1,0:$audio,0:$arLangId,0:$enLangId";
}

if (!$inputPath) {
    $inputPath = Read-Host Please Enter Video Path?;
}

if (!$prefix) {
    $prefix = "D:\Watch";
}
$outputPath = (& "D:\Programs\Shell-Scripts\Shared\Show File Selector.ps1" $prefix)[-1];
Write-Output "Output folder will be $outputPath"
$pathAsAfile = Get-Item $inputPath;
if ($pathAsAfile -isnot [System.IO.DirectoryInfo]) {
    $enLangId, $arLangId, $audio = GetIds -filePath "$inputPath";

    $outputFilePath = "$outputPath/$($pathAsAfile.Name)";
    if ($removeSent) {
        $outputFilePath = "$outputPath/" + $pathAsAfile.Name -replace $removeSent;
    }

    Start-Convert-Video `
        -inputPath "$inputPath" `
        -outputPath $outputFilePath `
        -enLangId $enLangId `
        -arLangId $arLangId `
        -audio $audio;

    Remove-Item "$inputPath";
}
else {
    
    $filter = Read-Host "Start with?";

    if (!$filter) { $filter = ""; }

    Get-ChildItem -Path $inputPath -Filter "$filter*.mkv" | Foreach-Object {
        echo "Proccessing $inputPath/$_";
        $enLangId, $arLangId, $audio = GetIds -filePath "$inputPath/$_";
        $outputFilePath = "$outputPath/$_";
        if ($removeSent) {
            $outputFilePath = "$outputPath/" + $_ -replace $removeSent;
        }

        Start-Convert-Video `
            -inputPath "$inputPath/$_" `
            -outputPath $outputFilePath `
            -enLangId $enLangId `
            -arLangId $arLangId `
            -audio $audio;
    }

    Get-ChildItem -Path $inputPath -Filter "$filter*.mkv" | Foreach-Object {
        Remove-Item "$inputPath/$_";
    }
}

Write-Output "CLOSING IN 3 SEC";
Start-Sleep -Seconds 3;
