#region Functions

$codecExtensionMapper = @{
    # Audio
    "aac"                = ".aac"
    "m4a"                = ".m4a"
    "mp3"                = ".mp3"
    # Subtitles
    "ass"                = ".ass" # ASS (Advanced SSA) subtitle (decoders: ssa ass) (encoders: ssa ass)
    "srt"                = ".srt" # SubRip subtitle with embedded timing
    "subrip"             = ".srt" # SubRip subtitle (decoders: srt subrip) (encoders: srt subrip)
    "dvb_subtitle"       = ".sub" # DVB subtitles (decoders: dvbsub) (encoders: dvbsub)
    "dvd_subtitle"       = ".sub" # DVD subtitles (decoders: dvdsub) (encoders: dvdsub)
    "subviewer"          = ".sub" # SubViewer subtitle
    "subviewer1"         = ".sub" # SubViewer v1 subtitle
    "hdmv_pgs_subtitle"  = ".sup" # HDMV Presentation Graphic Stream subtitles (decoders: pgssub)
    "hdmv_text_subtitle" = ".sup" # HDMV Text subtitle
    "jacosub"            = ".jss" # JACOsub subtitle
    "microdvd"           = ".sub" # MicroDVD subtitle
    "mpl2"               = ".mpl" # MPL2 subtitle
    "pjs"                = ".pjs" # PJS (Phoenix Japanimation Society) subtitle
    "realtext"           = ".rt" # RealText subtitle
    "sami"               = ".smi" # SAMI subtitle
    "ssa"                = ".ssa" # SSA (SubStation Alpha) subtitle
    "stl"                = ".stl" # Spruce subtitle format
    "vplayer"            = ".txt" # VPlayer subtitle
    "webvtt"             = ".vtt" # WebVTT subtitle
};


function HandleTrack {
    param (
        $fileInfo,
        $trackInfo
    )

    $trackInfo ??= GetTrackInfo($pathInfo.FullName);
    Extract -FileInfo $fileInfo `
        -index $trackInfo.Index `
        -extension $trackInfo.Extension;
}

function GetTrackInfo($inputPath) {
    $streamsInfo = & ffprobe -v error -print_format json -show_entries `
        "stream=index,codec_name,codec_type,codec_long_name:stream_tags=language" `
        "$inputPath" | ConvertFrom-Json;
    $tracks = @($streamsInfo.streams | Where-Object { $codecExtensionMapper.ContainsKey($_.codec_name) })
    foreach ($track in $tracks) {
        $extension = $codecExtensionMapper[$track.codec_name];
        Write-Host "$($track.index) => $extension - $($track.codec_long_name) - $($track.codec_type) - $($track.tags.language)";
    }
    $streamOrder = (Read-Host "Please Enter StreamOrder") -as [int];
    $selectedTrack = $tracks | Where-Object { $_.index -eq $streamOrder };
    return @{
        Index     = $streamOrder
        Extension = $codecExtensionMapper[$selectedTrack.codec_name]
    }
}

function Extract {
    param (
        [System.IO.FileInfo]$FileInfo,
        [int]$index,
        [string]$extension
    )

    $fileDirectoryName = $FileInfo.DirectoryName;
    $fileName = $FileInfo.Name.replace($FileInfo.Extension, "$extension");
    $output = "$fileDirectoryName\$fileName";
    & ffmpeg "-v" "error" "-i" "$($FileInfo.FullName)" "-map" "0:$index" "$output";
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