$sharedArgs = @();


$strip = & Prompt.ps1 -title "Remove Metadata" -message "Do You Want To Remove Metadata?" -defaultValue $true;
if ($strip) {
    $sharedArgs += "-strip";
}

$quality = & Range-Selector.ps1 -title "Quality" -message "Select Quality" -minimum 75 -maximum 100  -defaultValue 100  -tickFrequency 5;
if ($quality -ne 100) {
    $sharedArgs += @("-quality", [int]$quality);
}

$newSize = & Options-Selector.ps1 @("AsSource" , "2560x1440", "1920x1080", "1024x768") "-title" "Select Image Resoluation" -defaultValue "AsSource";
if ($newSize -ne "AsSource") {
    $sharedArgs += @("-resize", "$newSize");
}


$sharedArgs += @(
    "-interlace", "JPEG"
);
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