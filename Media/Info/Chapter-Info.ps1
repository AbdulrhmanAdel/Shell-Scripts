$ffmpegPath = "D:\Programs\Media\Tools\yt\ffmpeg.exe"
$file = "D:\Watch\Anime\3-GATSU NO LION\Season 2\3-gatsu no Lion II - 22 (BD 720p) (Commie) (A0E57FC8).mkv"
function GetChapters {
    param($path)
    $ffmpegOutput = & $ffmpegPath -loglevel error -i $path -f ffmetadata -;
    $chapters = @()
    for ($i = 0; $i -lt $ffmpegOutput.Length; $i++) {
        if ($ffmpegOutput[$i] -match "\[CHAPTER\]") {
            $timebase = [int64]($ffmpegOutput[++$i] -replace "TIMEBASE=1/", "")
            $start = [int64]($ffmpegOutput[++$i] -replace "START=", "") / $timebase;
            $end = [int64]($ffmpegOutput[++$i] -replace "END=", "") / $timebase;
            $lenght
            $chapter = @{
                Start  = $start
                End    = $end
                Length = $end - $start
                Title  = $ffmpegOutput[++$i] -replace "title=", ""
            }
            $chapters += $chapter
        }
    }

    # Output the chapters array
    return $chapters
}

$chapters = GetChapters -path $file | Sort-Object -Property Start, End;
Write-Host "DONE";