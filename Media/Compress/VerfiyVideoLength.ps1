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
    
    $json = & mediaInfo --Output=JSON """$videoPath""" | ConvertFrom-Json;
    foreach ($track in $json.media.track) {
        $trackType = $track.'@type'; 
        if ($trackType -eq "Video") {
            $duration = [int]$track.'Duration';
            return $duration;
        }

        if ($trackType -eq "Audio") {
            $duration = [int]$track.'Duration';
            return $duration;
        }
    }

    return 0
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

function CheckFile {
    param (
        $sourceFilePath,
        $destinitionFilePath
    )
    
    if (!(Test-Path -LiteralPath $destinitionFilePath)) {
        Write-Output  "Destinition $destinitionFilePath Does't exist";
        return;
    }

    $isSoruceVideo = IsVideo -videoPath $sourceFilePath;
    if (!$isSoruceVideo) {
        return;
    }

    $isDestVideo = IsVideo -videoPath $destinitionFilePath;
    if (!$isDestVideo) {
        Write-Output  "Destinition $destinitionFilePath Is't a video";
        return;
    }

    $sourceLength = GetDuration -videoPath $sourceFilePath;
    $destinitionLength = GetDuration -videoPath $destinitionFilePath;

    $diff = ($sourceLength - $destinitionLength);
    if ($sourceLength -ne $destinitionLength -and $diff -ne 1 -and $diff -ne -1) {
        Write-Output  "ERROR SOURCE $sourceFilePath length is $sourceLength ===> DES $destinitionFilePath length is $destinitionLength";
        return;
    }
}

function CheckDirectory {
    param (
        $sourceDirectory,
        $destinitionDirectory
    )
    
    $allFiles = Get-ChildItem -LiteralPath $sourceDirectory;
    foreach ($file in $allFiles) {
        $des = "$destinitionDirectory/" + $file.Name;
        CheckFile -sourceFilePath $file.FullName -destinitionFilePath $des
    }
}

$soruceFileCount = CalculateFileCount -folderPath $source;
$destinitionFileCount = CalculateFileCount -folderPath $destinition;
Write-Output "SOURCE: $soruceFileCount => DESTINITION: $destinitionFileCount"
$childern = Get-ChildItem -LiteralPath $source;
foreach ($child in $childern) {
    $ouputChildDirectory = "$destinition/" + $child.Name;
    if ($child -is [System.IO.DirectoryInfo]) {
        CheckDirectory -sourceDirectory $child.FullName -destinitionDirectory  $ouputChildDirectory
        continue;
    }

    CheckFile -sourceFilePath $child.FullName -destinitionFilePath $ouputChildDirectory;
}

Write-Output "DONE";