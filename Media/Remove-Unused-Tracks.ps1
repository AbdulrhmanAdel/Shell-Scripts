$prefix = "D:\Watch";
$inputFiles = $args;
$outputPath = & Folder-Picker.ps1 $prefix;
if (!$outputPath) {
    return;
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
        "--video-tracks", [int]$videoTrack.StreamOrder
    );

    #region Audio
    $audioTracks = @($tracks | Where-Object { $_.'@type' -eq 'Audio' });
    $audioId = $null;
    if ($audioTracks.Length -gt 1) {
        $nonEnglishTrack = $audioTracks | Where-Object { $_.Language -ne "en" -and $_.Language -ne "eng" -and $_.Title -ne "English" };
        if ($nonEnglishTrack) {
            $audioId = [int]$nonEnglishTrack.StreamOrder;
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

    $engSubTracks = @($subtitleTracks | Where-Object { $_.Language -match "(?i)en|eng|English" });
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
    
    if ($p.ExitCode -eq 0) {
        Remove-Item -LiteralPath $inputPath -Force;
        Write-Host "Handling File COMPLETED SUCCESSFULLY " -ForegroundColor Green;
    }
    else {
        Write-Host "FAILD Processing File. ExitCode: $($p.ExitCode)" -ForegroundColor Red;
    }

    Write-Host "==========================" -ForegroundColor DarkBlue;
}

foreach ($inputPath in $inputFiles) {
    $pathAsAfile = Get-Item -LiteralPath $inputPath;
    if ($pathAsAfile -isnot [System.IO.DirectoryInfo]) {
        $newName = $pathAsAfile.Name.Replace($removeSent, "");
        $outputFilePath = "$outputPath\$newName";
        RemoveUnusedTracks -inputPath $inputPath -outputPath $outputFilePath;
    }
    else {
        $filter = Read-Host "Start with?";
        if (!$filter) { $filter = ""; }
        Get-ChildItem -Path $inputPath -Filter "$filter*.mkv" | Foreach-Object {
            $outputFilePath = "$outputPath\$_";
            if ($removeSent) {
                $outputFilePath = "$outputPath\" + $_.Name.Replace($removeSent, "");
            }
    
            RemoveUnusedTracks -inputPath $_.FullName -outputPath $outputFilePath;
        }

        $childens = Get-ChildItem -Path $inputPath;
        if ($childens.Length -eq 0) {
            Remove-Item -LiteralPath $inputPath -Force;
        }
    }
}

timeout.exe 5;
