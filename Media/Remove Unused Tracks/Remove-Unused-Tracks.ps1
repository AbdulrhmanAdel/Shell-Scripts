Write-Host "V2"
$mkvmerge = "D:\Programs\Media\Tools\mkvtoolnix\mkvmerge.exe";
$mediaInfo = "D:\Programs\Media\Tools\MediaInfo\MediaInfo.exe";
$prefix = "D:\Watch";
$inputFiles = $args;
$outputPath = & "D:\Education\Projects\MyProjects\Shell-Scripts\Shared\Folder-Picker.ps1" $prefix;
if (!$outputPath) {
    return;
}
# $removeSent = Read-Host "Do you want to remove any char from video file?";
$removeSent = "-PSA";
function RemoveUnusedTracks(
    $inputPath,
    $outputPath
) {
    try {
        $command = "--output ""$outputPath""";
        $json = &$mediaInfo  --Output=JSON "$inputPath" | ConvertFrom-Json;
        $audioTracks = @($json.media.track | Where-Object { $_.'@type' -eq 'Audio' });
        $subtitleTracks = @($json.media.track | Where-Object { $_.'@type' -eq 'Text' });
        $trackOrder = "0:0,0:1";

        $audioId = $null;
        if ($audioTracks.Length -gt 1) {
            $nonEnglishTrack = $audioTracks | Where-Object { $_.Language -ne "en" -and $_.Language -ne "eng" -and $_.Title -ne "English" };
            if ($nonEnglishTrack) {
                $audioId = [int]$nonEnglishTrack.ID - 1;
            }
        }
        if (!$audioId) {
            $audioId = [int]$audioTracks[0].ID - 1
        }
    
        $command += " --audio-tracks ""$audioId""";
        $trackOrder += ",0:$audioId"

        $subTracks = "";
        $arSubTracks = @($subtitleTracks | Where-Object { $_.Language -eq "ara" -or $_.Language -eq "ar" -or $_.Title -contains "Arabic" });
        if ($arSubTracks.Length -gt 0) {
            $arSubTrack = $arSubTracks[0];
            $arSubTrackId = [int]$arSubTrack.ID - 1;
            $subTracks = "$arSubTrackId";
            $trackOrder += ",0:$arSubTrackId"
            $command += " --default-track-flag ""$($arSubTrackId):yes"""
            $command += " --forced-display-flag ""$($arSubTrackId):yes"""
        }
        $engSubTracks = @($subtitleTracks | Where-Object { $_.Language -eq "en" -or $_.Language -eq "eng" -or $_.Title -eq "English" });
        if ($engSubTracks.Length -gt 0) {
            $engSubTrack = $engSubTracks[0];
            $engSubTrackId = [int]$engSubTrack.ID - 1;
            if ($subTracks.Length -gt 0) {
                $subTracks += ",$engSubTrackId";
            }
            else {
                $subTracks = "$engSubTrackId";
            }
            $trackOrder += ",0:$engSubTrackId"
        }

        if ($subTracks.Length -gt 0) {
            $command += " --subtitle-tracks ""$subTracks""";
        }

        $command += " ""$inputPath"" --track-order ""$trackOrder"""

        $processInfo = New-Object System.Diagnostics.ProcessStartInfo;
        $processInfo.FileName = $mkvmerge;
        $processInfo.Arguments = "$command";
        $processInfo.RedirectStandardError = $true
        $processInfo.RedirectStandardOutput = $true
        $processInfo.UseShellExecute = $false;
        $p = New-Object System.Diagnostics.Process;
        $p.StartInfo = $processInfo;
        $p.Start();
        $p.WaitForExit();
        $stdout = $p.StandardOutput.ReadToEnd();
        Write-Output $stdout;
        $hasError = $stdout.Contains("Error:");
        if (!$hasError) {
            Remove-Item -LiteralPath $inputPath -Force;
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Host "ERROR $_";
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

timeout.exe -Seconds 5;
