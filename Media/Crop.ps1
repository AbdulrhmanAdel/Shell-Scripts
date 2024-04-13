$ffmpeg = "D:\Programs\Media\Tools\yt\ffmpeg.exe";
$filePath = $args[0];
$fileExtension = [System.IO.Path]::GetExtension($filePath);
$outputPath = $filePath.Replace($fileExtension, ".cropped$fileExtension");
$start = [int](Read-Host "Start?");
$end = [int](Read-Host "End?");
if ($end -eq 0) {
    exit;
}
$commandArgs = @(
    "-y",
    "-ss", $start, 
    "-to", $end, 
    "-i", """$filePath""",
    """$outputPath""");

Start-Process -FilePath $ffmpeg -ArgumentList $commandArgs -NoNewWindow;