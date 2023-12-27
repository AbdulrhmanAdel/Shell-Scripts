$handbrakeCli = "D:\Programs\Media\Tools\HandBrake\HandBrake CLI\HandBrakeCLI.exe";
$filePath = $args[0];

$fileInfo = Get-Item -LiteralPath $filePath;
if ($fileInfo -is [System.IO.DirectoryInfo]) {
    return;
}

Write-Host "PLEASE choose quality 1:480, 2:720, 3:1080";
$quality = Read-Host "Please enter quailty";
$height = 1280;
$width = 720;
switch ($quality) {
    "1" { $height = 640; $width = 480; break; }
    "3" { $height = 1920; $width = 1080; break; }
}

$newFileName = $fileInfo.Name.Replace($fileInfo.Extension, " ($height) X ($width)$($fileInfo.Extension)")
$newFilePath = "$($fileInfo.Directory)\$newFileName";
&$handbrakeCli `
    --encoder "x264" `
    -q 23 `
    -T `
    --optimize `
    --width $height `
    --height $width `
    --encoder-preset "Veryfast" `
    -i $filePath `
    -o $newFilePath; 
