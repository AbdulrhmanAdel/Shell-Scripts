$mediaInfo = "D:\Programs\Media\Tools\MediaInfo\MediaInfo.exe";
$mkvExtractPath = "D:\Programs\Media\Tools\mkvtoolnix\mkvextract.exe";

function ExtractTrack {
    param (
        $fileInfo,
        $trackInfo
    )
    $fileDirectoryName = $fileInfo.DirectoryName;
    $fileName = $fileInfo.Name.replace($fileInfo.Extension, ".$($trackInfo["extension"])");
    $output = "$fileDirectoryName\$fileName";

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $mkvExtractPath;
    $processInfo.UseShellExecute = $false;
    $processInfo.Arguments = "tracks ""$($fileInfo.FullName)"" $($trackInfo["index"]):""$output"""
    $process = [System.Diagnostics.Process]::Start($processInfo)
    $process.WaitForExit();
}

function GetTrackInfo($inputPath) {
    $json = &$mediaInfo  --Output=JSON "$inputPath" | ConvertFrom-Json;
    $tracks = $json.media.track | Where-Object { $_.'@type' -eq "Text" -or $_.'@type' -eq "Audio" }
    foreach ($track in $tracks) {
        Write-Host "$($track.ID) =>  $($track.Title) - $($track.'@type') - $($track.Language)";
    }
    $trackId = (Read-Host "Please Enter TrackId") -as [int];
    $selectedTrack = $tracks | Where-Object { $_.ID -eq $trackId };
    return @{
        index     = $selectedTrack.ID - 1
        extension = $selectedTrack.Format.ToLower()
    };
}

$trackInfo = $null;
$files = $args | Where-Object { $_.EndsWith(".mkv") }
foreach ($folderPath in $files) {
    $pathInfo = Get-Item -LiteralPath $folderPath;
    if ($pathInfo -is [System.IO.DirectoryInfo]) {
        $files = Get-ChildItem -LiteralPath $pathInfo.FullName -Filter "*.mkv";
        $trackInfo = GetTrackInfo($files[0].FullName);
        foreach ($file in $files) {
            ExtractTrack -fileInfo $file -trackInfo $trackInfo;
        }
    }
    else {
        if (!$trackInfo) {
            $trackInfo = GetTrackInfo($pathInfo.FullName);
        }
        ExtractTrack -fileInfo $pathInfo -trackInfo $trackInfo;
    }
}


timeout.exe 5;