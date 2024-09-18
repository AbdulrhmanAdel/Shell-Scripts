#region Functions

$codecSettings = @{
    # Audio
    "aac"          = @{ Type = "a"; Encoder = "aac"; Extension = ".aac" }
    "m4a"          = @{ Type = "a"; Encoder = "aac"; Extension = ".m4a" }
    "opus"         = @{ Type = "a"; Encoder = "libopus"; Extension = ".opus" }
    "mp3"          = @{ Type = "a"; Encoder = "libmp3lame"; Extension = ".mp3" }
    # Subtitles
    # ASS (Advanced SSA) subtitle (decoders: ssa ass) (encoders: ssa ass)
    "ass"          = @{ Type = "s"; Encoder = "ass"; Extension = ".ass" }
    # SubRip subtitle with embedded timing
    "srt"          = @{ Type = "s"; Encoder = "srt"; Extension = ".srt" }
    # SubRip subtitle (decoders: srt subrip) (encoders: srt subrip)
    "subrip"       = @{ Type = "s"; Encoder = "subrip"; Extension = ".srt" }
    # DVB subtitles (decoders: dvbsub) (encoders: dvbsub)
    # "dvb_subtitle" = @{ Type = "s"; Encoder = "dvbsub"; Extension = ".sub" }
    # # DVD subtitles (decoders: dvdsub) (encoders: dvdsub)
    # "dvd_subtitle" = @{ CustomHandler = {
    #     & mkvextract 
    # }; Extension = ".idx" }
};


function HandleTrack {
    param (
        $fileInfo,
        $trackInfo
    )

    $trackInfo ??= GetTrackInfo($pathInfo.FullName);

    if ($trackInfo.CustomHandler) {
        $trackInfo.CustomHandler.Invoke($fileInfo, $trackInfo);
        return;
    }

    Extract -FileInfo $fileInfo `
        -trackInfo $trackInfo;
}

function GetTrackInfo($inputPath) {
    $streamsInfo = & ffprobe -v error -print_format json -show_entries `
        "stream=index,codec_name,codec_type,codec_long_name:stream_tags=language" `
        "$inputPath" | ConvertFrom-Json;
    $tracks = @($streamsInfo.streams | Where-Object { $codecSettings.ContainsKey($_.codec_name) })
    $options = $tracks | ForEach-Object {
        $extension = ($codecSettings[$selectedTrack.codec_name]).Extension;
        $text = "$($_.tags.language) - $extension - $($_.codec_long_name)";
        return @{
            Key   = $text
            Value = $_.index
        } 
    };
    $streamOrder = Options-Selector.ps1 -options $options --mustSelectOne
    $selectedTrack = $tracks | Where-Object { $_.index -eq $streamOrder };
    return @{
        Index    = $streamOrder
        Settings = $codecSettings[$selectedTrack.codec_name]
    }
}

function Extract {
    param (
        [System.IO.FileInfo]$FileInfo,
        $trackInfo
    )
    $index = $trackInfo.Index;
    $extension = $trackInfo.Settings.Extension;
    $type = $trackInfo.Settings.Type;
    $encoder = $trackInfo.Settings.Encoder;
    $fileDirectoryName = $FileInfo.DirectoryName;
    $fileName = $FileInfo.Name.replace($FileInfo.Extension, "$extension");
    $output = "$fileDirectoryName\$fileName";
    Write-Host "ffmpeg '-v' 'error' '-i' '$($FileInfo.FullName)' '-c:$($type)'  $encoder '-map' '0:$index' '$output'"
    & ffmpeg "-v" "error" `
        "-i" "$($FileInfo.FullName)" `
        "-c:$($type)" "copy" `
        "-map" "0:$index" `
        "$output";
}

#endregion
$files = $args | Where-Object { Is-Video.ps1 $_; }
foreach ($folderPath in $files) {
    $pathInfo = Get-Item -LiteralPath $folderPath;
    if ($pathInfo -is [System.IO.DirectoryInfo]) {
        $files = Get-ChildItem -LiteralPath $pathInfo.FullName -Filter "*.mkv";
        $trackInfo = GetTrackInfo($files[0].FullName);
        foreach ($file in $files) {
            HandleTrack -fileInfo $file  -trackInfo $trackInfo;
        }
    }
    else {
        HandleTrack -fileInfo $pathInfo;
    }
}


timeout.exe 15;