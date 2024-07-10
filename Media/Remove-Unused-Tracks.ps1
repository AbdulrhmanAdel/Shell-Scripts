$outputPath = & Folder-Picker.ps1 -intialDirectory "D:\Watch";
if (!$outputPath) {
    return;
}

#region Functions
$englishRegex = "(?i)en|eng|English";
function isEnglishTrack {
    param (
        $track
    )
    
    return $track.Language -match $englishRegex -or $track.Title -match $englishRegex;
}

function ForceRename {
    param (
        $path,
        $newName
    )
    
    $RenameError = $null;
    Rename-Item -LiteralPath $path -NewName $newName -Force -ErrorVariable RenameError | Out-Null;
    if (!$RenameError.Count) {
        return
    }

    Read-Host $RenameError -ForegroundColor Red;
    ForceRename -path $path -newName $newName
}

$removeSent = "-PSA";
$preferEnglishTrack = @("hi");
function RemoveUnusedTracks(
    $inputPath,
    $outputPath
) {
    Write-Host "Handling File $inputPath" -ForegroundColor Green;

    if (Test-Path -LiteralPath $outputPath) {
        $outputPathInfo = Get-Item -LiteralPath $outputPath;
        $newName = $outputPathInfo.Name -replace "$($outputPathInfo.Extension)", " - OLD - $(Get-Date  -f yyyy-MM-dd)$($outputPathInfo.Extension)";
        Write-Output "File Already Exists: RENAMING IT TO $newName";
        ForceRename -path $outputPath -newName $newName;
        if ($inputPath -eq $outputPath) {
            $inputPath = "$($outputPathInfo.DirectoryName)\$newName";
        }
    }

    $tracks = (& mediaInfo --Output=JSON "$inputPath" | ConvertFrom-Json).media.track;
    $videoTrack = $tracks | Where-Object { $_.'@type' -eq 'Video' }
    $tracksOrder = @([int]$videoTrack.StreamOrder);
    $arguments = @(
        "-o", """$outputPath""",
        "--video-tracks", [int]$videoTrack.StreamOrder,
        "--no-attachments"
    );

    #region Audio
    $audioTracks = @($tracks | Where-Object { $_.'@type' -eq 'Audio' });
    $audioId = $null;
    if ($audioTracks.Length -gt 1) {
        $nonEnglishTrack = $audioTracks | Where-Object { !(isEnglishTrack -track $_) };
        if ($nonEnglishTrack -and $preferEnglishTrack -notcontains $nonEnglishTrack.Language) {
            $audioId = [int]$nonEnglishTrack.StreamOrder;
        }
        else {
            $englishTrack = $audioTracks | Where-Object { isEnglishTrack -track $_ };
            $audioId = [int]$englishTrack.StreamOrder
        }
    }
    if (!$audioId) {
        $audioId = [int]$audioTracks[0].StreamOrder
    }
    $arguments += @("--audio-tracks", $audioId);
    $tracksOrder += $audioId;
    #endregion

    #region Subtitles
    $subtitleTracks = @($tracks | Where-Object { $_.'@type' -eq 'Text' });
    $subTracks = @();
    $arSubTracks = @($subtitleTracks | Where-Object { $_.Language -match "(?i)ara|ar|Arabic" });
    if ($arSubTracks.Length -gt 0) {
        $arSubTrack = $arSubTracks[0];
        $arSubTrackId = [int]$arSubTrack.StreamOrder;
        $arguments += @("--default-track-flag", $arSubTrackId);
        $arguments += @("--forced-display-flag", $arSubTrackId);
        $subTracks += $arSubTrackId;
        $tracksOrder += $arSubTrackId;
    }

    $engSubTracks = @($subtitleTracks | Where-Object { isEnglishTrack -track $_ });
    if ($engSubTracks.Length -gt 0) {
        $engSubTrack = $engSubTracks[0];
        $engSubTrackId = [int]$engSubTrack.StreamOrder;
        $subTracks += $engSubTrackId;
        $tracksOrder += $engSubTrackId;
        $arguments += @("--default-track-flag", "$($engSubTrackId):0");
        $arguments += @("--forced-display-flag", "$($engSubTrackId):0");
    }

    $arguments += "--subtitle-tracks"; 
    $arguments += $subTracks -join ",";
       
    #endregion
    $arguments += """$inputPath""";
    $arguments += "--track-order"
    $arguments += ($tracksOrder | ForEach-Object { return "0:$_" }) -join ","

    $p = Start-Process mkvmerge -ArgumentList $arguments -NoNewWindow -PassThru -Wait;
    
    if ($p.ExitCode -gt 0) {
        Write-Host "FAILD Processing File. ExitCode: $($p.ExitCode)" -ForegroundColor Red;
        return $false;
    }

    Remove-Item -LiteralPath $inputPath -Force;
    Write-Host "Handling File COMPLETED SUCCESSFULLY " -ForegroundColor Green;
    return $true;
}

function GetFileFromDirectory {
    param (
        $directoryPath
    )

    $script:filter = Read-Host "Start with?";
    if (!$script:filter) { $script:filter = ""; }
    return Get-ChildItem -Path $directoryPath -Filter "$script:filter*.mkv";
}

function HandleFile {
    param (
        $pathAsAfile
    )


    if ($pathAsAfile -is [System.IO.DirectoryInfo]) { 
        $childern = GetFileFromDirectory -directoryPath $pathAsAfile.FullName;
        $childern | ForEach-Object { HandleFile -pathAsAfile $_; };
        return;
    }

    $directories += $pathAsAfile.DirectoryName;
    $inputPath = $pathAsAfile.FullName;
    $filePath = $inputPath;
    $newName = $pathAsAfile.Name.Replace($removeSent, "");
    $isArchive = $pathAsAfile.Extension -in $archiveExtensions
    if ($isArchive) {
        $fileName = $pathAsAfile.Name -replace '(\.zip|\.rar)$', '.mkv';
        $filePath = "$temp/$fileName";
        if (!(Test-Path -LiteralPath $filePath)) {
            $archiveProcess = Start-Process "C:\Program Files\7-Zip\7z.exe" -ArgumentList @(
                "x", 
                $inputPath, 
                "-o$temp"
            ) -NoNewWindow -PassThru -Wait;

            if ($archiveProcess.ExitCode -gt 0) {
                Write-Host "CAN'T Extract FILE $inputPath" -ForegroundColor Red
                return;
            }

            if (!(Test-Path -LiteralPath $filePath)) {
                Write-Host "INVALID FILE $inputPath" -ForegroundColor Red
                return; 
            }
        }

        $newName = $newName -replace '(\.zip|\.rar)$', '.mkv';
    }

    $outputFilePath = "$outputPath\$newName";
    $isSuccessed = RemoveUnusedTracks -inputPath $filePath -outputPath $outputFilePath;
    if ($isArchive -and $isSuccessed) {
        Remove-Item -LiteralPath $pathAsAfile.FullName -Force;
    }

    Write-Host "==========================" -ForegroundColor DarkBlue;
}

#endregion

$temp = $env:TEMP;
$directories = @();
$archiveExtensions = @('.rar', '.zip')
$filesExtensions = @('.mkv')
$allowedExtensions = $archiveExtensions + $filesExtensions;
$args | Where-Object { 
    if (!(Test-Path -LiteralPath $_ )) { return $false }
    $extension = [System.IO.Path]::GetExtension($_);
    return $extension -in $allowedExtensions 
} | ForEach-Object {
    $pathAsAfile = Get-Item -LiteralPath $_;
    HandleFile -pathAsAfile $pathAsAfile;
}

$ignoredFiles = @("PSArips.com.txt");
$directories | Select-Object -Unique | ForEach-Object {
    $measures = Get-ChildItem -LiteralPath $_ -Force | ForEach-Object {
        if ($_.Name -notin $ignoredFiles) {
            return $_;
        }
    } | Measure-Object;

    if ($measures.Count -ne 0) {
        return;
    }

    $removeDirectory = & Prompt.ps1 -title  "Remove Directory" -message $_;
    if ($removeDirectory) {

        Remove-Item -LiteralPath $_ -Force;
    }
}

timeout.exe 5;
