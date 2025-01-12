[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 1)]
    [string]
    $ImagePath,
    [string]
    $SavePath
)

Add-Type -AssemblyName System.Drawing;
Write-Host "Convert-Png-To-Ico ARGS $($args)" -ForegroundColor Yellow;

function ResizeImage {
    param (
        $oldImage,
        $newWidth,
        $newHeight
    )
    $newImage = New-Object System.Drawing.Bitmap($newWidth, $newHeight);
    $graphics = [System.Drawing.Graphics]::FromImage($newImage);

    # Set graphics quality settings for high-quality resizing
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality;
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias;

    # Draw the image with the new dimensions
    $graphics.DrawImage($oldImage, 0, 0, $newWidth, $newHeight);
    $graphics.Dispose();
    return $newImage;
}

#Convert The File
function ConvertImageToIco  (
    [string] 
    $sourceImagePath,
    $newFilePath,
    $sizes = @(256, 128, 64, 48, 32, 16)
) {
    
    Write-Host $args -ForegroundColor Green;
    Write-Host "sourceImagePath = $sourceImagePath" -ForegroundColor Green;
    Write-Host "newFilePath = $newFilePath" -ForegroundColor Green;
    # $sizes = 256, 128, 64, 48, 32, 16;
    # $sizes = 256, 128, 64, 48, 32, 16;
    # $sizes = 256, 128, 96, 64, 48, 32, 24, 16;
    # $sizes = 16, 24, 32, 48, 64, 96, 128, 256;
    # $sizes = 256, 128, 96, 64, 48, 32, 24, 16;

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
        Remove-Item -LiteralPath $newFilePath -Force;
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

if (!$SavePath) {
    $ImageInfo = Get-Item -LiteralPath $ImagePath;
    $IconName = Remove-UnwantedText.ps1 -Text ($ImageInfo.Name -replace $ImageInfo.Extension, ".ico");
    $SavePath = $ImageInfo.DirectoryName + "\" + $IconName;
}

ConvertImageToIco `
    -sourceImagePath $ImagePath `
    -newFilePath $SavePath;

return $SavePath;