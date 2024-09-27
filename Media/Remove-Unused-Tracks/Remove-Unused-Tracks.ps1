$outputPath = & Folder-Picker.ps1 -IntialDirectory "D:\Watch" -ExitIfNotSelected;

#region Functions
$removeSent = "-PSA|-Pahe\.in|\[AniDL\] ";
function RemoveUnusedTracks(
    $inputPath,
    $outputPath
) {
    Write-Host "Handling File $inputPath" -ForegroundColor Green;
    $process = & "$PSScriptRoot/Modules/Ffmpeg.ps1" $inputPath $outputPath;
    if ($process.ExitCode -gt 0) {
        Write-Host "FAILD Processing File. ExitCode: $($p.ExitCode)" -ForegroundColor Red;
        Write-Host "==========================" -ForegroundColor DarkBlue;
        return $false;
    }

    & Remove-ToRycleBin.ps1 $inputPath;
    Write-Host "Handling File COMPLETED SUCCESSFULLY " -ForegroundColor Green;
    Write-Host "==========================" -ForegroundColor DarkBlue;
    return $true;
}

function GetMediaFilesFromArchive {
    param (
        [System.IO.FileInfo]$archiveFileInfo
    )

    # $folderName = $archiveFileInfo.Name -replace $archiveFileInfo.Extension, '';
    $outputPath = "$temp/RUT-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')";
    if (Test-Path -LiteralPath $outputPath) {
        & Remove-ToRycleBin.ps1 $outputPath;
    }

    $archiveProcess = Start-Process "C:\Program Files\7-Zip\7z.exe" -ArgumentList @(
        "x", 
        $archiveFileInfo.FullName,
        "-o$outputPath"
    ) -NoNewWindow -PassThru -Wait;
    
    if ($archiveProcess.ExitCode -gt 0) {
        return @();
    }

    return Get-ChildItem -LiteralPath $outputPath -Filter "*.mkv" -Recurse;
}

function GetFileFromDirectory {
    param (
        $directoryPath
    )

    $script:filter = "";
    if (!$script:filter) { $script:filter = ""; }
    $files = Get-ChildItem -LiteralPath $directoryPath -Filter "$script:filter*.mkv";
    $directories = Get-ChildItem -LiteralPath $directoryPath -Directory;
    return $files + $directories;
}

function HandleFile {
    param (
        $pathAsAfile,
        $outputPath
    )

    if ($pathAsAfile -is [System.IO.DirectoryInfo]) {
        $outputFolderPath = "$outputPath/$($pathAsAfile.Name)";
        if (!(Test-Path -LiteralPath $outputFolderPath)) {
            New-Item -ItemType Directory -Path $outputFolderPath;
        }
        $childern = GetFileFromDirectory -directoryPath $pathAsAfile.FullName;
        $childern | ForEach-Object { HandleFile -pathAsAfile $_ -outputPath  $outputFolderPath; };
        return;
    }

    $inputPath = $pathAsAfile.FullName;
    $newName = $pathAsAfile.Name -replace $removeSent, "";
    $outputFilePath = "$outputPath\$newName";
    if (Test-Path -LiteralPath $outputFilePath) {
        $outputPathInfo = Get-Item -LiteralPath $outputFilePath;
        $newName = $outputPathInfo.Name -replace "$($outputPathInfo.Extension)", " - OLD - $(Get-Date  -f yyyy-MM-dd)$($outputPathInfo.Extension)";
        Write-Output "File Already Exists: RENAMING IT TO $newName";
        & Force-Rename.ps1 -path $outputFilePath -newName $newName;
        if ($inputPath -eq $outputFilePath) {
            $inputPath = "$($outputPathInfo.DirectoryName)\$newName";
        }
    }
    return RemoveUnusedTracks -inputPath $inputPath -outputPath $outputFilePath;
}

#endregion

$temp = $env:TEMP;
$archiveExtensions = @('.rar', '.zip', '.7z');
$args | Where-Object { 
    return Test-Path -LiteralPath $_
} | ForEach-Object {
    $pathAsAfile = Get-Item -LiteralPath $_;
    if ($pathAsAfile -is [System.IO.DirectoryInfo] -or $pathAsAfile.Extension -eq ".mkv") {
        HandleFile -pathAsAfile $pathAsAfile -outputPath $outputPath;
        return;
    }

    $isArchive = $pathAsAfile.Extension -in $archiveExtensions
    if (!$isArchive) {
        return;
    }

    $mediaFromArchive = GetMediaFilesFromArchive -archiveFileInfo $pathAsAfile;
    $results = $mediaFromArchive | ForEach-Object {
        $removeTracksResult = HandleFile -pathAsAfile $_ -outputPath $outputPath;
        if ($removeTracksResult ) {
            return $true;
        }

        return $false;
    }
        
    if ($results -notcontains $false) {
        & Remove-ToRycleBin.ps1 $_;

        if ($isArchive) {
            $hasParts = $_ -match "(?<Name>.*)part/d+";
            if ($hasParts) {
                & Remove-ToRycleBin.ps1 $_;
            }
        }
    }
}
timeout.exe 5;
