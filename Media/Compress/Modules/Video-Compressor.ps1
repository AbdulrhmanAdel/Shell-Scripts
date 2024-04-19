$selector = "Options-Selector.ps1";
$width, $height = (((& $selector @("480x640", "720x1280", "1080x1920")) -split "x") | ForEach-Object { return [int]$_ }) ?? @(720, 1280);
$encoder = (& $selector @("x264", "x265", "x265_10bit")) ?? "x264";
$encoderPreset = (& $selector @( 
        "ultrafast",
        "superfast",
        "veryfast",
        "faster",
        "fast",
        "medium"
    ) title="Select Encoder Preset") ?? "veryfast";
$allowedExtensions = "mkv$|mp4$";
$files = @(
    $args | Where-Object {
        if (!(Test-Path -LiteralPath $_)) {
            return $false;
            
        }
        return $_ -match $allowedExtensions;
    });

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

$files | ForEach-Object {
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