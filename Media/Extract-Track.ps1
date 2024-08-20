function ExtractTrack {
    param (
        $fileInfo,
        $trackInfo
    )
    $fileDirectoryName = $fileInfo.DirectoryName;
    $fileName = $fileInfo.Name.replace($fileInfo.Extension, ".$($trackInfo["extension"])");
    $output = "$fileDirectoryName\$fileName";
    
    $processArgs = @(
        """$($fileInfo.FullName)""",
        "tracks",
        """$($trackInfo["index"]):$output"""
    );
    Start-Process mkvextract -NoNewWindow -Wait `
        -ArgumentList $processArgs;
}

function GetTrackInfo($inputPath) {
    $json = & mediaInfo  --Output=JSON "$inputPath" | ConvertFrom-Json;
    $tracks = $json.media.track | Where-Object { $_.'@type' -eq "Text" -or $_.'@type' -eq "Audio" }
    foreach ($track in $tracks) {
        Write-Host "$($track.StreamOrder) =>  $($track.Title) - $($track.'@type') - $($track.Language) - $($track.Format)";
    }
    $streamOrder = (Read-Host "Please Enter StreamOrder") -as [int];
    $selectedTrack = $tracks | Where-Object { $_.StreamOrder -eq $streamOrder };
    $format = $selectedTrack.Format.ToLower();
    if ($format -notin @("srt", "ass")) {
        $format = "srt";
    }
    
    return @{
        index     = $selectedTrack.StreamOrder
        extension = $format
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