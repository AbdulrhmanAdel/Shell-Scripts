$destinitionPath = $args[0];

$defaultHandler = { & yt-dlp -f "ba" -x --audio-format m4a -o "$destinitionPath\\%(title)s" $url; };
$options = @{
    "mp3"    = { & yt-dlp -f "ba" -x --audio-format mp3 --audio-quality 160K  -o "$destinitionPath\\%(title)s" $url; }
    "m4a"    = { & yt-dlp -f "ba" -x --audio-format m4a --audio-quality 160K  -o "$destinitionPath\\%(title)s" $url; }
    "480p"   = { & yt-dlp -f "bestvideo[height<=480]+bestaudio[ext=m4a]" -o "$destinitionPath\\%(title)s.%(ext)s" $url; }
    "720p"   = { & yt-dlp -f "bestvideo[height<=720]+bestaudio[ext=m4a]" -o "$destinitionPath\\%(title)s.%(ext)s" $url; }
    "Cancel" = { EXIT }
}

if (!$destinitionPath) {
    $destinitionPath = Read-Host "Please enter destinition path?";
}

$format = & Options-Selector.ps1 -options $options.Keys -title "Please enter format you want?" --mustSelectOne;
function download {
    $url = Read-Host "Please enter url?";
    $handler = $options[$format] ?? $defaultHandler;
    Invoke-Command -ScriptBlock $handler -NoNewScope;
    if ($url) {
        download;
    }
}

download;