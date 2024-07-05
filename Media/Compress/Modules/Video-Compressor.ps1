# DOCS URL https://handbrake.fr/docs/en/latest/cli/command-line-reference.html 
#region function


$outputPath = & Folder-Picker.ps1;
function Compress {
    param (
        $file
    )
    
    $file = $_;
    Write-Host "Compressing $file" -ForegroundColor Green;
    $fileInfo = Get-Item -LiteralPath $file;
    $newFileName = $fileInfo.Name.Replace($fileInfo.Extension, " - $($height)x$($width)-$($encoder)-$($encoderPreset)$($fileInfo.Extension)")
    $newFilePath = "$($outputPath ?? $fileInfo.Directory)\$newFileName";
    if (Test-Path -LiteralPath $newFileName) {
        if (!(& Prompt.ps1 -message "File Already Exists. Do You Want To Override it?" -defaultValue $false)) {
            return;
        }
    }
    $arguments = @($sharedArgs) + @("-i", """$file""", "-o", """$newFilePath""");
    Start-Process handbrake -ArgumentList $arguments -NoNewWindow -PassThru -Wait;
    Write-Host "Compressing $file" -ForegroundColor Green;
}

#endregion

$selector = "Options-Selector.ps1";
$width, $height = (& $selector -options @("480x640", "720x1280", "1080x1920") -title "Select Video Resoluation" -defaultValue "720x1280") -split "x" | ForEach-Object { return [int]$_ };
$selectedVideoEncoder = & $selector -options @(
    "svt_av1",
    "svt_av1_10bit",
    "x264",
    "x264_10bit",
    "x265",
    "x265_10bit",
    "x265_12bit"
    # ,"nvenc_h264",
    # "nvenc_h265",
    # "nvenc_h265_10bit",
    # "mpeg4",
    # "mpeg2",
    # "VP8",
    # "VP9",
    # "VP9_10bit",
    # "theora"
) -title "Select Encoder Target" -defaultValue "x265";

$encoderPresetOptions = @( "ultrafast", "superfast", "veryfast", "faster", "fast", "medium")
$encoderPreset = & $selector -options $encoderPresetOptions -defaultValue "veryfast" -title "Select Encoding Speed Preset" ;



#region Audio
$selectedAudioEncoder = & $selector -options @(
    "none",
    "av_aac",
    "opus",
    "copy"
    "copy:aac",
    "ac3",
    "copy:ac3",
    "eac3",
    "copy:eac3",
    "copy:truehd",
    "copy:dts",
    "copy:dtshd",
    "copy:mp2",
    "mp3",
    "copy:mp3",
    "vorbis",
    "flac16",
    "flac24",
    "copy:flac",
    "copy:opus"
) -title "Select Audio Encoder Target" -defaultValue "av_aac";
#endregion

$sharedArgs = @(
    "--encoder", $selectedVideoEncoder,
    "-T",
    "--optimize",
    "--width", $height,
    "--height", $width,
    "--verbose=0",
    "--encoder-preset", $encoderPreset,
    "--aencoder", $selectedAudioEncoder
);

$qualtiyMethod = & $selector -options @("Quality", "BitRate") -defaultValue "Quality" -title "Quality Or BitRate" ;
switch ($qualtiyMethod) {
    "Quality" { 
        $quality = & Range-Selector.ps1 -title "Quality" -message "Select Quality (Lower Is Better)" -minimum 0 -maximum 51  -defaultValue 22  -tickFrequency 1;
        $sharedArgs += @("-q", $quality); break; 
    }
    "BitRate" { 
        $bitRate = Read-Host "Please Enter Target BitRate in KB";
        $sharedArgs += @("-b", $bitRate); break; 
    }
    Default {}
}

$frame = & $selector -options @(30, 60, 120, "As Source") -title "Select Frame Rate" -defaultValue "As Source";
if ($frame -ne "As Source") {
    $sharedArgs += @("--rate", $frame, "--pfr");
}

$keepSubtitles = & Prompt.ps1 -message "Do You Want To Keep Subtitles?" -defaultValue $true;
if ($keepSubtitles) {
    $sharedArgs += "--all-subtitles";
}

$allowedExtensions = "mkv$|mp4$";
$args | ForEach-Object {
    $info = Get-Item -LiteralPath $_ -ErrorAction Ignore;
    if (!$info) {
        return;
    }

    if ($info -is [System.IO.FileInfo] -and $info.Extension -match $allowedExtensions) {
        Compress -file $_;
        # CopyOriginalFile -File $_ -Destination "$($info.DirectoryName)\Original";
        return;
    } 

    $files = Get-ChildItem -LiteralPath $info.FullName -Filter $allowedExtensions;
    $files | ForEach-Object {
        Compress -file $_;
        # CopyOriginalFile -File $_ -Destination "$($info.DirectoryName)\Original";
    }
}
    