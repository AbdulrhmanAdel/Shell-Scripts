$source = $args[0];
$destinition = "$source (Converted)";
Write-Output $source;
function GetDuration {
    param (
        $videoPath
    )

    $windowsMediaPlayer = New-Object -ComObject WMPlayer.OCX
    $mediaItem = $windowsMediaPlayer.newMedia($videoPath)
    $length = $mediaItem.duration  # Duration is in seconds
    return $length;
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
    $isSoruceVideo = IsVideo -videoPath $sourceFilePath;
    if (!$isSoruceVideo) {
        return;
    }

    $sourceLength = GetDuration -videoPath $sourceFilePath;
    $destinitionLength = GetDuration -videoPath $destinitionFilePath;

    if ($sourceLength -ne $destinitionLength) {
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

$childern = Get-ChildItem -LiteralPath $source;
foreach ($child in $childern) {
    $ouputChildDirectory = "$destinition/" + $child.Name;
    if ($child -is [System.IO.DirectoryInfo]) {
        CheckDirectory -sourceDirectory $child.FullName -destinitionDirectory  $ouputChildDirectory
        continue;
    }

    CheckFile -sourceFilePath $child.FullName -outputPath $ouputChildDirectory;
}

Write-Output "DONE";