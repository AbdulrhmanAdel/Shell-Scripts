$handbrakeCli = "D:\Programs\Media\Tools\HandBrake\HandBrake CLI\HandBrakeCLI.exe";

function Encode {
    param (
        $inputPath,
        $outputPath
    )
    
    &$handbrakeCli `
        --encoder "x264" `
        -q 23 `
        -T `
        --optimize `
        --width 1280 `
        --height 720 `
        --encoder-preset "Veryfast" `
        -i $inputPath `
        -o $outputPath;
}

function CreateDirectoryIfNotExist {
    param (
        $path
    )
    
    if (Test-Path $path) {
        return $path;
    }

    return New-Item -Path $path -Force -ItemType Directory;
}


function CalculateFileCount {
    param (
        $folderPath
    )

    $count = 0;
    $files = Get-ChildItem  -LiteralPath $folderPath;
    foreach ($file in $files) {
        if ($file -is [System.IO.DirectoryInfo]) {
            $count += CalculateFileCount -folderPath  $file.FullName;
            continue;
        }
    
        $count += 1;
    }

    return $count;
}
    
$videoExtensions = @(".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".m4v", ".webm");
function HandleFile {
    param (
        $fileInfo,
        $outputPath
    )
    [System.Console]::Clear();

    Write-Host "HANDLING $global:currentFileNumber / $global:allFilesCount" -ForegroundColor red;
    
    $global:currentFileNumber += 1;
    $fileOutputPath = "$outputPath/" + $fileInfo.Name;
    if (Test-Path $fileOutputPath) {
        return;
    }

    if ($fileInfo.Extension.ToLower() -notin $videoExtensions) {
        Copy-Item -Path $fileInfo.FullName -Destination $fileOutputPath;
        return;
    }

    Encode -inputPath $fileInfo.FullName -outputPath $fileOutputPath;
}

function EncodeDirectory {
    param (
        $sourcePath,
        $outputPath
    )

    CreateDirectoryIfNotExist -path $outputPath;
    $allFiles = Get-ChildItem -LiteralPath $sourcePath;

    foreach ($file in $allFiles) {
        HandleFile -fileInfo $file -outputPath $outputPath;
    }
}

$coursePath = $args[0];
$coursePathInfo = Get-Item -LiteralPath $coursePath;
if ($coursePathInfo -is [System.IO.DirectoryInfo]) {
    $global:currentFileNumber = 1;
    $global:allFilesCount = CalculateFileCount -folderPath $coursePath;
    $convertedCoursePath = $coursePathInfo.FullName.Replace($coursePathInfo.Name, $coursePathInfo.Name + " (Converted)");
    CreateDirectoryIfNotExist -path $convertedCoursePath;
    $childern = Get-ChildItem -LiteralPath $coursePath;
    
    foreach ($child in $childern) {
        if ($child -is [System.IO.DirectoryInfo]) {
            $ouputChildDirectory = "$convertedCoursePath/" + $child.Name;
            EncodeDirectory -sourcePath $child.FullName -outputPath  $ouputChildDirectory
            continue;
        }
    
        HandleFile -fileInfo $child -outputPath $convertedCoursePath;
    }
    
    [System.Console]::Clear();
    Write-Host "HANDLED $global:currentFileNumber / $global:allFilesCount" -ForegroundColor red;
    Write-Output "DONE CONVERTING";
    Write-Output "Checking video's Lengths";
    Write-Output "START Checking";
    pwsh.exe -File "D:\Programs\Shell-Scripts\Media\HandBrake\VerfiyVideoLength.ps1" $coursePath;
    Write-Output "DONE Checking";
}
else {
    $convertedCoursePath = $coursePathInfo.FullName.Replace($coursePathInfo.Extension, ' (Converted)' + $coursePathInfo.Extension)
    Encode -inputPath $coursePathInfo.FullName -outputPath $convertedCoursePath;
}

Read-Host "Press Any key to exit.";