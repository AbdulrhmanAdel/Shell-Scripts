$inputPath = $args[0]
$outputPath = $args[1];
$streams = (
    & ffprobe -v error -print_format json -show_entries `
        "stream=index,codec_type:stream_tags=language" `
        "$inputPath" | ConvertFrom-Json
).streams;

$arguments = @(
    "-v", "error",
    "-stats",
    "-i", """$inputPath""", 
    "-map", "0:v"
);

$audioStreams = @($streams | Where-Object { $_.codec_type -eq "audio" });
$audioStream = $audioStreams | Where-Object { $_.tags.language -notmatch "en|eng|English|hin" } | Select-Object -First 1;
$audioStream ??= $audioStreams[0];
$arguments += @(
    "-map", "0:$($audioStream.index)"
)

$subtitleStreams = $streams | Where-Object { $_.codec_type -eq "subtitle" };
$subtitleStreams | Where-Object { $_.tags.language -match "ara|ar|Arabic" } | ForEach-Object {
    $arguments += @(
        "-map", "0:$($_.index)",
        "-disposition:$($_.index)", "default"
    );
}

$subtitleStreams | Where-Object { $_.tags.language -match "en|eng|English" } | ForEach-Object {
    $arguments += @(
        "-map", "0:$($_.index)",
        "-disposition:$($_.index)", "none"
    );
}

$arguments += @("-c", "copy");
$arguments += """$outputPath""";
return Start-Process ffmpeg `
    -ArgumentList $arguments `
    -NoNewWindow -PassThru -Wait;