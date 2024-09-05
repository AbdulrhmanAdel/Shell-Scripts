$outputPath = & Folder-Picker.ps1 -intialDirectory "D:\Watch" --ExitIfNotSelected;

#region Functions


$removeSent = "-PSA|-Pahe\.in";
$ignoredAudioLanguages = "hin?";
# $arRegex = [Regex]::new("ara|ar|Arabic"); ;
# $enRegex = [Regex]::new("en|eng|English");

function GetAudioId {
    param (
        $audioTracks
    )
    $audioTracks = @($audioTracks | ForEach-Object {
            return @{
                Id       = [int]$_.StreamOrder;
                Language = $_.Language
                Title    = $_.Title
            }
        });

    if ($audioTracks.Length -eq 1) {
        return $audioTracks[0].Id;
    }
    
    $preferedTracks = @($audioTracks | Where-Object { !($_.Language -match $ignoredAudioLanguages) });
    if ($preferedTracks.Length -eq 0) {
        return $audioTracks[0].Id;
    }

    if ($preferedTracks.Length -eq 1) {
        return $preferedTracks[0].Id;
    }

    $nonEnglishTrack = $preferedTracks | Where-Object { !($_.Language -match "en|eng|English") } | Select-Object -First 1;
    if ($nonEnglishTrack) {
        return $nonEnglishTrack.Id;
    }

    return $preferedTracks[0].Id;
}


function GetSubtitleTracks {
    param (
        $subtitleTracks
    )

    if ($subtitleTracks.Length -eq 0) {
        return $subtitleTracks;
    }

    $subTracks = @();
    $subtitleTracks | Where-Object {
        $_.Language -match "ara|ar|Arabic"
    } | ForEach-Object {
        $subTrackId = [int]$_.StreamOrder;
        $subTracks += @{
            Id     = $subTrackId
            Forced = $true
        };
    };

    $subtitleTracks | Where-Object {
        $_.Language -match "en|eng|English"
    } | ForEach-Object {
        $trackId = [int]$_.StreamOrder;
        $subTracks += @{
            Id     = $trackId
            Forced = $false
        };
    };

    return $subTracks
}
function RemoveUnusedTracks(
    $inputPath,
    $outputPath
) {
    Write-Host "Handling File $inputPath" -ForegroundColor Green;
    $tracks = (& mediaInfo --Output=JSON "$inputPath" | ConvertFrom-Json).media.track;
    $videoTrack = $tracks | Where-Object { $_.'@type' -eq 'Video' }
    $tracksOrder = @([int]$videoTrack.StreamOrder);
    $arguments = @(
        "-o", """$outputPath""",
        "--video-tracks", [int]$videoTrack.StreamOrder,
        "--no-attachments"
        # "--quiet"
    );

    #region Audio
    $audioTracks = @($tracks | Where-Object { $_.'@type' -eq 'Audio' });
    $audioId = GetAudioId -audioTracks $audioTracks;
    $arguments += @("--audio-tracks", $audioId);
    $tracksOrder += $audioId;
    #endregion

    #region Subtitles
    $subtitleTracks = @($tracks | Where-Object { $_.'@type' -eq 'Text' });
    $subTracks = GetSubtitleTracks -subtitleTracks $subtitleTracks;
    if ($subTracks.Length -gt 0) {
        $subTracksIds = $subTracks | ForEach-Object { return $_.Id.ToString() };
        $arguments += "--subtitle-tracks"; 
        $arguments += $subTracksIds -join ",";
        $subTracks | ForEach-Object {
            $subId = $_.Id;
            $forced = $_.Forced;
            $arguments += @("--default-track-flag", "$subId$($forced ? '' : ':0')");
            $arguments += @("--forced-display-flag", "$subId$($forced ? '' : ':0')");
            $tracksOrder += $subTracksIds;
        }
    }
    else {
        $arguments += "--no-subtitles";
    }
    #endregion

    $arguments += """$inputPath""";
    $arguments += "--track-order"
    $arguments += ($tracksOrder | ForEach-Object { return "0:$_" }) -join ","

    $p = Start-Process mkvmerge -ArgumentList $arguments -NoNewWindow -PassThru -Wait;
    if ($p.ExitCode -gt 0) {
        Write-Host "FAILD Processing File. ExitCode: $($p.ExitCode)" -ForegroundColor Red;
        Write-Host "==========================" -ForegroundColor DarkBlue;
        return $false;
    }

    & Remove-To-Rycle-Bin.ps1 $inputPath;
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
        & Remove-To-Rycle-Bin.ps1 $outputPath;
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
        & Remove-To-Rycle-Bin.ps1 $_;

        if ($isArchive) {
            $hasParts = $_ -match "(?<Name>.*)part/d+";
            if ($hasParts) {
                & Remove-To-Rycle-Bin.ps1 $_;
            }
        }
    }
}
timeout.exe 5;
