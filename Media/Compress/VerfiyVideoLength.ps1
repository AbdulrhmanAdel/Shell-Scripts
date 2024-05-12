$source = $args[0]
$destinition = "$source (Converted)";
Write-Output $source;
function GetDuration {
    param (
        $videoPath
    )

    if (!(Test-Path -LiteralPath $videoPath)) {
        Write-Output "FILE $videoPath DOESN'T EXITS";
    }
    
    $info = & mediaInfo --Output=JSON $videoPath | ConvertFrom-Json;
    $videoTrack = @($info.media.track | Where-Object { $_.'@type' -eq 'Video' })[0]
    $audioTrack = @($info.media.track | Where-Object { $_.'@type' -eq 'Audio' })[0]
    return @{
        VideoDuration = [double]($videoTrack.Duration)
        AudioDuration = [double]($audioTrack.Duration)
    }
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
function IsVideo {
    param (
        $videoPath
    )
    
    $videoInfo = Get-Item -LiteralPath $videoPath;
    return $videoInfo.Extension.ToLower() -in $videoExtensions
}


function Check {
    param (
        $source,
        $target
    )
    
    $sourceInfo = Get-Item -LiteralPath $source;
    if ($sourceInfo -isnot [System.IO.DirectoryInfo]) {
        if ($sourceInfo.Extension -notin @(".mp4", ".mkv")) { return; }
        $sourceDurations = GetDuration -videoPath $source;
        $targetDurations = GetDuration -videoPath $target;
        $videoRange = $sourceDurations.VideoDuration - $targetDurations.VideoDuration;
        $audioRange = $sourceDurations.AudioDuration - $targetDurations.AudioDuration;
        if (($videoRange -le 1 -and $videoRange -ge -1) -or ($audioRange -le 1 -and $audioRange -ge -1)) {
            Write-Host "$source MATCH $target $videoRange - $audioRange" -ForegroundColor Green
            return 
        }

        Write-Host "$source NOT MATCH $target" -ForegroundColor Red
        return;
    }

    $childern = Get-ChildItem -LiteralPath $source;
    $childern | ForEach-Object { 
        $targetFilePath = "$target/" + $_.Name;
        Check -source $_.FullName -target $targetFilePath 
    };
}

Check -source $source -target  $destinition 
# $soruceFileCount = CalculateFileCount -folderPath $source;
# $destinitionFileCount = CalculateFileCount -folderPath $destinition;
# Write-Output "SOURCE: $soruceFileCount => DESTINITION: $destinitionFileCount"
# $childern = Get-ChildItem -LiteralPath $source;
# foreach ($child in $childern) {
#     $ouputChildDirectory = "$destinition/" + $child.Name;
#     if ($child -is [System.IO.DirectoryInfo]) {
#         CheckDirectory -sourceDirectory $child.FullName -destinitionDirectory  $ouputChildDirectory
#         continue;
#     }

#     CheckFile -sourceFilePath $child.FullName -destinitionFilePath $ouputChildDirectory;
# }

# Write-Output "DONE";