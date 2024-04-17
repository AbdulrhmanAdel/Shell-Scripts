Write-Host "V2"
$prefix = "D:\Watch";
$inputFiles = $args;
$outputPath = & "D:\Programming\Projects\Personal Projects\Shell-Scripts\Shared\Folder-Picker.ps1" $prefix;
if (!$outputPath) {
    return;
}
# $removeSent = Read-Host "Do you want to remove any char from video file?";
$removeSent = "-PSA";
function RemoveUnusedTracks(
    $inputPath,
    $outputPath
) {
    $oldName = $null;
    if (Test-Path -LiteralPath $outputPath) {
        Write-Output "File Already Exists"
        $outputFile = Get-Item -LiteralPath $outputPath;
        $oldName = $outputFile.Name;
        $outputPath = $outputPath -replace "$($outputFile.Extension)", " - Converted$($outputFile.Extension)"
    }

    $tracks = (& mediaInfo  --Output=JSON "$inputPath" | ConvertFrom-Json).media.track;
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
    Write-Host $p.ExitCode -ForegroundColor Red;
    if ($p.ExitCode -eq 0) {
        Remove-Item -LiteralPath $inputPath -Force;
        if ($oldName) {
            Rename-Item -LiteralPath $outputPath -NewName $oldName;
        }
    }
}

foreach ($inputPath in $inputFiles) {
    $pathAsAfile = Get-Item -LiteralPath $inputPath;
    if ($pathAsAfile -isnot [System.IO.DirectoryInfo]) {
        $newName = $pathAsAfile.Name.Replace($removeSent, "");
        $outputFilePath = "$outputPath/$newName";
        RemoveUnusedTracks -inputPath $inputPath -outputPath $outputFilePath;
    }
    else {
        $filter = Read-Host "Start with?";
        if (!$filter) { $filter = ""; }
        Get-ChildItem -Path $inputPath -Filter "$filter*.mkv" | Foreach-Object {
            $outputFilePath = "$outputPath/$_";
            if ($removeSent) {
                $outputFilePath = "$outputPath/" + $_.Name.Replace($removeSent, "");
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
