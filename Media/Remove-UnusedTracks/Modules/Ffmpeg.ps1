param (
    $inputPath,
    $outputPath
)

$inputPath ??= $args[0]
$outputPath ??= $args[1];


$english = @("en", "eng", "english");
$arabic = @("ara", "ar", "Arabic");
$notPreferedLanguages = @("hin");
function GetAudioIds {
    param (
        [System.Object[]]$AudioStreams
    )
    
    if ($AudioStreams.Length -eq 1) {
        return @($AudioStreams[0].index);
    }

    $accpetedAudio = @($AudioStreams | Where-Object { $_.tags.language -notin $notPreferedLanguages });
    if ($accpetedAudio.Length -eq 1) {
        return @($accpetedAudio[0].index);
    }

    $nonEnglishTracks = @($accpetedAudio | Where-Object { $_.tags.language -notin $english });
    if ($nonEnglishTracks.Length -ne 0) {
        return $nonEnglishTracks | ForEach-Object { return $_.index }
    }

    return @($accpetedAudio[0] ?? $AudioStreams[0]);
}

$streams = (
    & ffprobe -v error -print_format json -show_entries `
        "stream=index,codec_type:stream_tags=language" `
        "$inputPath" | ConvertFrom-Json
).streams;

$arguments = @(
    "-v", "error",
    "-stats",
    "-i", """$inputPath""", 
    "-map", "0:0"
);

#region Audio
$audioStreamsIds = GetAudioIds -AudioStreams @($streams | Where-Object { $_.codec_type -eq "audio" });
$audioStreamsIds | ForEach-Object {
    $arguments += @(
        "-map", "0:$($_)"
    )
}
#endregion

#region Subtitle
$subs = @();
$subtitleStreams = $streams | Where-Object { $_.codec_type -eq "subtitle" };
$subtitleStreams | Where-Object { $_.tags.language -in $arabic } | ForEach-Object {
    $subs += $_;
}
$subtitleStreams | Where-Object { $_.tags.language -in $english } | ForEach-Object {
    $subs += $_;
}

for ($i = 0; $i -lt $subs.Count; $i++) {
    $sub = $subs[$i];
    $arguments += @(
        "-map", "0:$($sub.index)"
    )

    $disposition = $i -eq 0 ? "default+forced" : "none";
    $arguments += @("-disposition:s:$i", $disposition);
}
#endregion

$arguments += @("-c", "copy");
$arguments += """$outputPath""";

return Start-Process ffmpeg `
    -ArgumentList $arguments `
    -NoNewWindow -PassThru -Wait;