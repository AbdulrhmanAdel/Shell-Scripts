$destinitionPath = $args[0];

$defaultHandler = @( "-f", "ba" , "-x", "--audio-format", "m4a", "--audio-quality", "160K");
$options = @{
    "mp3"    = @( "-f", "ba", "-x", "--audio-format", "mp3", "--audio-quality", "160K") 
    "m4a"    = @( "-f", "ba" , "-x", "--audio-format", "m4a", "--audio-quality", "160K") 
    "opus"   = @( "-f", "ba" , "-x", "--audio-format", "opus", "--audio-quality", "56K") 
    "480p"   = @( "-f", "bestvideo[height<=480]+bestaudio[ext=m4a]")
    "720p"   = @( "-f", "bestvideo[height<=720]+bestaudio[ext=m4a]")
    "Cancel" = { EXIT }
}

if (!$destinitionPath) {
    $destinitionPath = Read-Host "Please enter destinition path?";
}

$format = & Options-Selector.ps1 -options @(
    "mp3",
    "m4a",
    "opus",
    "480p",
    "720p",
    "Cancel"
) -title "Please enter format you want?" --mustSelectOne;

if ($format -eq "Cancel") {
    EXIT;
}


$selectedOptions = $options[$format] ?? $defaultHandler;

function HandlePlaylist {
    param (
        $url
    )

    $arguments = $selectedOptions;
    $from = Read-Host "FROM?";
    $to = Read-Host "TO?";
    if ($from) {
        $arguments += @("--playlist-start", $from);
    }
    if ($to) {
        $arguments += @("--playlist-end", $to);
    }

    $arguments += @("-o", """$destinitionPath\%(playlist_index)s - %(title)s""", $url);
    Start-Process yt-dlp -ArgumentList $arguments  -Wait -NoNewWindow;
}


$playlistRegex = "https\:\/\/.*\/playlist\?list=.*"
function download {
    $url = Read-Host "Please enter url?";
    if (!$url) {
        Write-Host "Please enter valid url?";
        download;
    }

    $isPlaylist = $url -match $playlistRegex;
    if ($isPlaylist) {
        HandlePlaylist -url $url;
    }
    else {
        $arguments = $selectedOptions + @("-o", """$destinitionPath\%(title)s.%(ext)s""", $url);
        Start-Process yt-dlp -ArgumentList $arguments  -Wait -NoNewWindow;
    }

    download;
}

download;