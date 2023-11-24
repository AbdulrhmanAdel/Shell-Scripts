Write-Output "$args";
Add-Type -AssemblyName System.Drawing;
enum SourceType {
    FromBrowser = 0
    FromLink = 1
    FromPath = 2
}

$directoryPath = $args[0];
$imageSourceType = [SourceType]$args[1];
$directory = Get-Item -LiteralPath $directoryPath -Force;


function DonwloadImage {
    param (
        $imageName,
        $imageUrl
    )

    if (-not $imageUrl) {
        $imageUrl = Read-Host "Please Enter Icon Url.";
    }
    
    $tempPath = "C:\WINDOWS\Temp";
    $tempFilePath = "$tempPath\$imageName.png";

    if (Test-Path -LiteralPath $tempFilePath) {
        if (-not (Read-Host "Do you want to Use Image From Cache?")) {
            return $tempFilePath;
        }

        Remove-Item -LiteralPath $tempFilePath -Force
    }

    $tempImage = New-Item "$tempFilePath"; 
    Invoke-WebRequest -UseBasicParsing -uri $imageUrl -outfile $tempFilePath;
    return $tempImage.FullName;
}

$filePath = "";
switch ($imageSourceType) {
    "FromBrowser" {
        Start-Process "https://www.google.com/search?tbm=isch&q=$($directory.Name) Icon";
        $tempUrl = DonwloadImage -imageName $directory.Name;
        $filePath = $tempUrl;
    }
    "FromLink" { 
        $imageUrl = $args[2];
        $tempUrl = DonwloadImage -imageName $directory.Name -imageUrl $imageUrl;
        $filePath = $tempUrl;
    }
    "FromPath" { 
        $filePath = Read-Host "Please Enter Icon Path.";
    }
}

Write-Output "Image Location = $filePath"

function ResizeImage {
    param (
        $oldImage,
        $newWidth,
        $newHeight
    )
    $newImage = New-Object System.Drawing.Bitmap($newWidth, $newHeight);
    $graphics = [System.Drawing.Graphics]::FromImage($newImage);
    $graphics.DrawImage($oldImage, 0, 0, $newWidth, $newHeight);
    $graphics.Dispose();
    return $newImage;
}

#Convert The File
function ConvertImageToIco  (
    [string] 
    $sourceImagePath,
    $newFilePath,
    $sizes
) {
    if (!$sizes) {
        $sizes = 256, 128, 64, 48, 32, 16;
    }

    $sourceImage = New-Object System.Drawing.Bitmap($sourceImagePath)
    $imageStreams = [System.IO.MemoryStream[]]::new($sizes.Length);
    for ($i = 0; $i -lt $sizes.Length; $i++) {
        $size = $sizes[$i];
        $newImage = ResizeImage -oldImage $sourceImage -newWidth $size -newHeight $size;
        $memStream = New-Object System.IO.MemoryStream;
        $newImage.Save($memStream, [System.Drawing.Imaging.ImageFormat]::Png);
        $imageStreams[$i] = $memStream;
    }
    $sourceImage.Dispose();
    if (Test-Path -LiteralPath $newFilePath) {
        Remove-Item -LiteralPath $newFilePath;
    }

    $iconFileStream = New-Object System.IO.FileStream($newFilePath, [System.IO.FileMode]::OpenOrCreate);
    $binaryWriter = New-Object System.IO.BinaryWriter($iconFileStream);
    
    $binaryWriter.Write([byte]0);
    $binaryWriter.Write([byte]0);
    $binaryWriter.Write([byte]1);
    $binaryWriter.Write([byte]0); 
    $binaryWriter.Write([int16] $sizes.Length);
    
    $offset = [int](6 + (16 * $sizes.Length));
    for ($i = 0; $i -lt $imageStreams.Count; $i++) {
        $size = $sizes[$i];
        if ($size -gt 255) {
            $size = 0;
        } 

        $currentImageStream = $imageStreams[$i];
        $currentImageLenght = [int]$currentImageStream.Length;
        $binaryWriter.Write([byte]$size);
        $binaryWriter.Write([byte]$size);
        $binaryWriter.Write([byte]0);
        $binaryWriter.Write([byte]0);
        $binaryWriter.Write([int16]1);
        $binaryWriter.Write([int16]32);
        $binaryWriter.Write($currentImageLenght);
        $binaryWriter.Write([int]$offset);
        $offset += $currentImageLenght;
    }
    
    foreach ($imageStream in $imageStreams) {
        $binaryWriter.Write($imageStream.ToArray());
    }

    $binaryWriter.Flush();
    $binaryWriter.Close();

    foreach ($imageStream in $imageStreams) {
        $imageStream.Dispose();
    }
    $sourceImage.Dispose();
}

#Create icon from downloaded image and move it to folder path
$iconPath = "$directoryPath\$($directory.Name).ico";
ConvertImageToIco `
    -sourceImagePath $filePath `
    -newFilePath $iconPath;

$iconFile = Get-Item -LiteralPath $iconPath -Force;
$iconFile.Attributes += 'Hidden'
$iconFile.Attributes += 'System'

# Change Folder Icon
$desktopPathFile = "$directoryPath\desktop.ini";

function Set-Desktop-File {
    if (Test-Path -LiteralPath $desktopPathFile) {
        Remove-Item -LiteralPath $desktopPathFile -Force;
    }
    
    $newItem = New-Item -Path $desktopPathFile -Force;
    $newItem.Attributes += 'Hidden';
    $newItem.Attributes += 'System';
    
    $fileContent = "[.ShellClassInfo]", "IconResource=.\$($directory.Name).ico,0";
    Set-Content -LiteralPath $desktopPathFile -Value $fileContent;

    if (!$directory.Attributes.HasFlag([System.IO.FileAttributes]::ReadOnly)) {
        $directory.Attributes += 'ReadOnly';
    }
}

Set-Desktop-File

# Invoke-Item $directory.Parent.FullName;

# Read-Host "Press Any Key To Exits";
