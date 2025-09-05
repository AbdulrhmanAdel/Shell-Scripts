[CmdletBinding()]
param (
    $DestinationPath,
    $Link,
    $Format,
    $NoExit
)

if (!$DestinationPath) {
    $DestinationPath = & Folder-Picker.ps1 -Required;
}

$defaultHandler = @( "-f", "ba" , "-x", "--audio-format", "m4a", "--audio-quality", "160K");
$options = @{
    "mp3"    = @( "-f", "ba", "-x", "--audio-format", "mp3", "--audio-quality", "160K") 
    "m4a"    = @( "-f", "ba" , "-x", "--audio-format", "m4a", "--audio-quality", "160K") 
    "opus"   = @( "-f", "ba" , "-x", "--audio-format", "opus", "--audio-quality", "56K") 
    "480p"   = @( "-f", "bestvideo[height<=480]+bestaudio[ext=m4a]")
    "720p"   = @( "-f", "bestvideo[height<=720]+bestaudio[ext=m4a]")
    "Cancel" = { EXIT }
}

if (!$DestinationPath) {
    $DestinationPath = Read-Host "Please enter destinition path?";
}

$Format ??= & Single-Options-Selector.ps1 -Options @(
    "mp3",
    "m4a",
    "opus",
    "480p",
    "720p",
    "Cancel"
) -Title "Please enter format you want?" -Required;

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

    $arguments += @("-o", """$DestinationPath\%(playlist_index)s - %(title)s""", $url);
    Start-Process yt-dlp -ArgumentList $arguments  -Wait -NoNewWindow;
}


$playlistRegex = "https\:\/\/.*\/playlist\?list=.*"
function download {
    param(
        $url    
    )
    $isPlaylist = $url -match $playlistRegex;
    if ($isPlaylist) {
        HandlePlaylist -url $url;
    }
    else {
        $arguments = $selectedOptions + @("-o", """$DestinationPath\%(title)s.%(ext)s""", $url);
        Start-Process yt-dlp -ArgumentList $arguments  -Wait -NoNewWindow;
    }
}

if (!$Link) {
    $urls = Input.ps1 -Title "Please enter url(s) separated by new lines" -MultiLine;
    $urls.Split([Environment]::NewLine) | ForEach-Object {
        download -url $_;
    }
    while ($NoExit) {
        $urls = Input.ps1 -Title "Please enter url(s) separated by new lines" -MultiLine;
        $urls.Split([Environment]::NewLine) | ForEach-Object {
            download -url $_;
        }
    }
    Exit;
}

download -url $Link;