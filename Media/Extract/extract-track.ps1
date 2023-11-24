$folderPath = $args[0];
function Convert {
    param (
        $fileInfo
    )
    $fileDirectoryName = $fileInfo.DirectoryName;
    $fileName = $fileInfo.Name.replace($fileInfo.Extension, ".$trackExtension");
    $output = "$fileDirectoryName\$fileName";
    &$mkvExtractPath tracks $fileInfo.FullName $tractIndex":"$output;
}

$mkvExtractPath = "D:\Programs\Media\Tools\mkvtoolnix\mkvextract.exe";
$pathInfo = Get-Item -LiteralPath $folderPath;
$trackExtension = Read-Host "Enter Track Extension ";
$tractIndex = Read-Host "Enter Track Index "; 

if ($pathInfo -is [System.IO.DirectoryInfo]) {
    $files = Get-ChildItem -LiteralPath $pathInfo.FullName -Filter "*.mkv";
    foreach ($file in $files) {
        Convert -fileInfo $file;
    }
}
else {
    Convert -fileInfo $pathInfo;
}

Write-Host "CLOSING IN 5 SECs";
Start-Sleep -Seconds 5;