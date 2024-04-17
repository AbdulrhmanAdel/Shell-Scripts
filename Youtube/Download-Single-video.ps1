
$destinitionPath = $args[0];

if (!$destinitionPath) {
    $destinitionPath = Read-Host "Please enter destinition path?";
}

Write-Host "Please enter format you want?"
Write-Host "1: Audio - MP3";
Write-Host "2: Audio - M4A";
Write-Host "3: video 480P";
Write-Host "4: video 720P";
$format = Read-Host "Format: ";
$url = Read-Host "Please enter url?";



function download {
    switch ($format) {
        1 { & yt-dlp -f "ba" -x --audio-format mp3 --audio-quality 160K  -o "$destinitionPath\\%(title)s" $url; }
        2 { & yt-dlp -f "ba" -x --audio-format m4a --audio-quality 160K  -o "$destinitionPath\\%(title)s" $url; }
        3 { & yt-dlp -f "bestvideo[height<=480]+bestaudio[ext=m4a]" -o "$destinitionPath\\%(title)s.%(ext)s" $url; }
        4 { & yt-dlp -f "bestvideo[height<=720]+bestaudio[ext=m4a]" -o "$destinitionPath\\%(title)s.%(ext)s" $url; }
        Default { & yt-dlp -f "ba" -x --audio-format m4a -o "$destinitionPath\\%(title)s" $url; }
    }

    $url = Read-Host "Please enter url?";

    if ($url) {
        download;
    }
}

download;