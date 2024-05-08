# DOCS URL https://handbrake.fr/docs/en/latest/cli/command-line-reference.html 

#region function

function Compress {
    param (
        $file
    )
    
    $file = $_;
    Write-Host "Compressing $file" -ForegroundColor Green;
    $fileInfo = Get-Item -LiteralPath $file;
    $newFileName = $fileInfo.Name.Replace($fileInfo.Extension, " - $($height)x$($width)-$($encoder)-$($encoderPreset)$($fileInfo.Extension)")
    $newFilePath = "$($fileInfo.Directory)\$newFileName";
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

$encoder = & $selector -options @("x264", "x265", "x265_10bit") -title "Select Encoder Target" -defaultValue "x265";

$encoderPresetOptions = @( "ultrafast", "superfast", "veryfast", "faster", "fast", "medium")
$encoderPreset = & $selector -options $encoderPresetOptions -defaultValue "veryfast" -title "Select Encoding Speed Preset" ;
$quality = & Range-Selector.ps1 -title "Quality" -message "Select Quality (Lower Is Better)" -minimum 0 -maximum 51  -defaultValue 22  -tickFrequency 1;

# $audioEncoder = 
$sharedArgs = @(
    "--encoder", $encoder,
    "-q", $quality,
    "-T",
    "--optimize",
    "--width", $height,
    "--height", $width,
    "--verbose=0",
    "--encoder-preset", $encoderPreset,
    "--aencoder", "av_aac"
);


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
    