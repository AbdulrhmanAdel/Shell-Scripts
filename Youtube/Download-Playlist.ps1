$yt = "yt-dlp";
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
$from = Read-Host "FROM?";
$to = Read-Host "TO?";

if ($from) {
    $from = " --playlist-start $from";
}

if ($to) {
    $to = " --playlist-end $to";
}

switch ($format) {
    1 { $yt += " -f 'ba' -x --audio-format mp3 --audio-quality 160K  --yes-playlist $from $to -o '$destinitionPath\\%(playlist_index)s - %(title)s' $url;" }
    2 { $yt += " -f 'ba' -x --audio-format m4a --audio-quality 160K  --yes-playlist $from $to -o '$destinitionPath\\%(playlist_index)s - %(title)s' $url;" }
    3 { $yt += " -f 'bestvideo[height<=480]+bestaudio[ext=m4a]'  --yes-playlist $from $to -o '$destinitionPath\\%(playlist_index)s - %(title)s.%(ext)s' $url;" }
    4 { $yt += " -f 'bestvideo[height<=720]+bestaudio[ext=m4a]'  --yes-playlist $from $to -o '$destinitionPath\\%(playlist_index)s - %(title)s.%(ext)s' $url;" }
}

Write-Host "$yt";
$processInfo = New-Object System.Diagnostics.ProcessStartInfo;
$processInfo.FileName = "powershell";
$processInfo.Arguments = "-Command  $yt";
$processInfo.UseShellExecute = $false;
[System.Diagnostics.Process]::Start($processInfo)
