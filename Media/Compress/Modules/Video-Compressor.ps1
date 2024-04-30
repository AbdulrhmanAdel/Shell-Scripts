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
        Write-Host "Already Compressed $file" -ForegroundColor Red;
        return;
    }
    $arguments = @($sharedArgs) + @("-i", """$file""", "-o", """$newFilePath""");
    Start-Process handbrake -ArgumentList $arguments -NoNewWindow -PassThru -Wait;
    Write-Host "Compressing $file" -ForegroundColor Green;
}

$selector = "Options-Selector.ps1";
$width, $height = (((& $selector @("480x640", "720x1280", "1080x1920") "-title=Select Video Resoluation") -split "x") | ForEach-Object { return [int]$_ }) ?? @(720, 1280);
$encoder = (& $selector @("x264", "x265", "x265_10bit") "-title=Select Encoder Target") ?? "x264";
$encoderPreset = (& $selector @( 
        "ultrafast",
        "superfast",
        "veryfast",
        "faster",
        "fast",
        "medium"
    ) "-title=Select Encoding Speed Preset") ?? "veryfast";

$sharedArgs = @(
    "--encoder", $encoder,
    "-q", 23,
    "-T",
    "--optimize",
    "--width", $height,
    "--height", $width,
    "-r", 30, "--pfr",
    "--verbose=0",
    "--encoder-preset", $encoderPreset
);

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
    