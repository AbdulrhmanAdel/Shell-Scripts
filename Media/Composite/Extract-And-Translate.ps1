[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$codes = @{
    "subrip" = "srt"
    "ass"    = "ass"
}
function Extract-EnglishTrack {
    param (
        $FilePath
    )
    
    $streamsInfo = & ffprobe -v error -print_format json -show_entries `
        "stream=index,codec_name,codec_type,codec_long_name:stream_tags=language" `
        "$FilePath" | ConvertFrom-Json;

    $stream = $streamsInfo.streams | Foreach-Object { 
        $data = $codes[$_.codec_name];
        if ($_.tags.language -in @("en", "eng", "english") -and $data) {
            return @{
                Ext   = $data
                Index = $_.index
            };
        }
    } | Select-Object -Last 1;
    
    if ($stream) {
        $subPath = "$($env:TEMP)\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').$($stream.Ext)";
        & ffmpeg "-y" "-v" "error" `
            "-stats" `
            "-i" "$($FilePath)" `
            "-map" "0:$($stream.Index)" `
            "-c" "copy" `
            "$subPath" ;
        return $subPath;
    }

    return $null;
}


$Files | ForEach-Object {
    $englishTrack = Extract-EnglishTrack -FilePath $_;
    & "D:\Programming\Projects\Personal Projects\Shell-Scripts\Media\Subtitles\Translate\Translate.ps1" $englishTrack;
    $ext = [System.IO.Path]::GetExtension($englishTrack);
    $translatedSubName = $englishTrack -replace $ext, ".ar$ext";
    $videoExt = [System.IO.Path]::GetExtension($_);
    $target = $_ -replace $videoExt, "$ext";
    Copy-Item -LiteralPath $translatedSubName -Destination $target;
}

