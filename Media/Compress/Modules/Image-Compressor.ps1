$selector = "Options-Selector.ps1";
$newSize = (& $selector @("AsSource" , "2560x1440", "1920x1080", "1024x768")) ?? "AsSource";
$quality = (& $selector @("75", "100")) ?? "75";

$sharedArgs += @(
    "-strip", 
    "-interlace", "JPEG",
    "-quality", [int]$quality);
if ($newSize -ne "AsSource") {
    $sharedArgs += @("-resize", "$newSize");
}

$args | ForEach-Object {
    $file = $_;
    Write-Host "Compressing $file" -ForegroundColor Green;
    $fileInfo = Get-Item -LiteralPath $file;
    $currentDate = Get-Date;
    $newFileName = $fileInfo.Name.Replace($fileInfo.Extension, " - $($currentDate.Ticks).jpg")
    $newFilePath = "$($fileInfo.Directory)\$newFileName";
    $arguments = @("""$file""") + @($sharedArgs) + @("""$newFilePath""");
    Start-Process magick -ArgumentList $arguments -Wait -NoNewWindow;
}