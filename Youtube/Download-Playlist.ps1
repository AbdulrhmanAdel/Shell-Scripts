$destinitionPath = $args[0];
if (!$destinitionPath) {
    $destinitionPath = Read-Host "Please enter destinition path?";
}

$format = & Options-Selector.ps1 @("mp3", "m4a", "480p", "720p");
$arguments = @("--yes-playlist", "-f");
switch ($format) {
    { $_ -eq "mp3" -or $_ -eq "m4a" } { 
        $arguments += @("ba", "-x", "--audio-format", $format, "--audio-quality", "160K");
    }
    { $_ -eq "480" -or $_ -eq "720" } { 
        $arguments += @("bestvideo[height<=$format]+bestaudio[ext=m4a]" );
    }
    Default {
        Write-Host "Invalid format selected exiting..." -ForegroundColor Red;
        Start-Sleep -Seconds 5;
        EXIT;
    }
}
$url = Read-Host "Please enter url?";
$from = Read-Host "FROM?";
$to = Read-Host "TO?";
if ($from) {
    $arguments += @("--playlist-start", $from);
}
if ($to) {
    $arguments += @("--playlist-end", $to);
}

$arguments += @("-o", """$destinitionPath\\%(playlist_index)s - %(title)s""", $url);
Start-Process yt-dlp -ArgumentList $argument -Wait -NoNewWindow -PassThru;
