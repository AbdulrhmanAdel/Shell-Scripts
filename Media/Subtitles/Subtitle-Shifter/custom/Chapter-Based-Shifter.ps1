$ffmpegPath = "D:\Programs\Media\Tools\yt\ffmpeg.exe"

function Handle {
    param ($videoFile, $subFile)
    $ffmpegOutput = & $ffmpegPath -i $videoFile -f ffmetadata -
    $startTime = $null;
    for ($i = 0; $i -lt $ffmpegOutput.Count; $i++) {
        $element = $ffmpegOutput[$i];
        if ($element -eq "[Chapter]") {
            $title = $ffmpegOutput[$i + 4] -replace "title=", "";
            if ($title -eq "Intro") {
                $startTime = ([double]($ffmpegOutput[$i + 3] -replace "END=", "")) / 1000000000;
                break;
            }
            $i += 5;
        }
    }

    $delayMilliseconds = "-90000";
    if ($startTime) {
        $startTime = "startAtTime=$startTime";
    }
    else {
        $startTime = "";
        $delayMilliseconds = "-90500"
    }

    & "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Subtitles\Subtitle-Shifter\handlers\Old\Srt-Subtitle-Shifter.ps1" `
        "file=$subFile" `
        $startTime `
        "delayMilliseconds=$delayMilliseconds"

    if ($startTime) {
        & "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Subtitles\Subtitle-Shifter\handlers\Old\Srt-Subtitle-Shifter.ps1" `
            "file=$subFile" `
            "delayMilliseconds=500"
    }
}



foreach ($file in $args) {
    $info = Get-Item -LiteralPath $file;
    $videInfo = "$($info.Directory)/$($info.Name -replace ".srt", ".mkv")"
    Handle -videoFile $videInfo `
        -subFile $file;
}