$args[0] | Where-Object { $_ -match "\.ass" } | ForEach-Object {
    $file = $_;
    $srtFileName = $file -replace ".ass", ".srt";
    $arguments = @(
        "-v", "error",
        "-stats",
        "-i", """$file"""
        "-c", "subrip"
        """$srtFileName"""
    );
    Start-Process ffmpeg `
        -ArgumentList $arguments `
        -Wait -NoNewWindow -PassThru;
};

timeout.exe 15;
