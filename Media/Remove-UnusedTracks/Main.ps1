[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$outputPath = & Folder-Picker.ps1 -InitialDirectory "E:\Watch" -ExitIfNotSelected;

#region Functions
function RemoveUnusedTracks(
    $inputPath,
    $outputPath
) {
    Write-Host "Handling File $inputPath" -ForegroundColor Green;
    $process = & "$PSScriptRoot/Modules/Ffmpeg.ps1" $inputPath $outputPath;
    if ($process.ExitCode -gt 0) {
        Write-Host "FAILED Processing File. ExitCode: $($p.ExitCode)" -ForegroundColor Red;
        Write-Host "==========================" -ForegroundColor DarkBlue;
        return $false;
    }

    & Remove-ToRecycleBin.ps1 $inputPath -Color ([System.ConsoleColor]::Green);
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
        & Remove-ToRecycleBin.ps1 $outputPath;
    }

    $archiveProcess = Start-Process 7z -ArgumentList @(
        "x", 
        """$($archiveFileInfo.FullName)""",
        "-o$outputPath"
    ) -NoNewWindow -PassThru -Wait;
    
    if (!$archiveProcess -or $archiveProcess.ExitCode -gt 0) {
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
        $pathAsAFile,
        $outputPath
    )

    if ($pathAsAFile -is [System.IO.DirectoryInfo]) {
        $outputFolderPath = "$outputPath/$($pathAsAFile.Name)";
        if (!(Test-Path -LiteralPath $outputFolderPath)) {
            New-Item -ItemType Directory -Path $outputFolderPath;
        }
        $children = GetFileFromDirectory -directoryPath $pathAsAFile.FullName;
        $children | ForEach-Object { HandleFile -pathAsAFile $_ -outputPath  $outputFolderPath; };
        return;
    }

    $inputPath = $pathAsAFile.FullName;
    $newName = Remove-UnwantedText.ps1 -Text $pathAsAFile.Name;
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
$Files | Where-Object { 
    return Test-Path -LiteralPath $_
} | ForEach-Object {
    $pathAsAFile = Get-Item -LiteralPath $_;
    if ($pathAsAFile -is [System.IO.DirectoryInfo] -or $pathAsAFile.Extension -eq ".mkv") {
        HandleFile -pathAsAFile $pathAsAFile -outputPath $outputPath;
        return;
    }

    $isArchive = $pathAsAFile.Extension -in $archiveExtensions
    if (!$isArchive) {
        return;
    }

    $mediaFromArchive = GetMediaFilesFromArchive -archiveFileInfo $pathAsAFile;
    $results = $mediaFromArchive | ForEach-Object {
        $removeTracksResult = HandleFile -pathAsAFile $_ -outputPath $outputPath;
        if ($removeTracksResult) {
            return $true;
        }

        return $false;
    }

    if (!$results -or $results.Length -eq 0 -or $results -contains $false) {
        return;
    }

    $extension = $pathAsAFile.Extension;
    $regex = "(?<Name>.*)part\d+\$extension$"
    $hasParts = $pathAsAFile.Name -match $regex;
    if ($hasParts) {
        Get-ChildItem -LiteralPath $pathAsAFile.Directory.FullName | Where-Object {
            $_.Name.StartsWith($Matches["Name"]);
        } | ForEach-Object {
            & Remove-ToRecycleBin.ps1 $_.FullName;
        }

        return;
    }

    & Remove-ToRecycleBin.ps1 $_;
}

timeout.exe 5;
