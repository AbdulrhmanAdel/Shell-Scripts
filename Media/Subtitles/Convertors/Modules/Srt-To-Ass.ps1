$args[0] | Where-Object { $_ -match "\.srt" } | ForEach-Object {
    $file = $_;
    $srtFileName = $file -replace ".srt", ".ass";
    $arguments = @(
        "-v", "error",
        "-stats",
        "-i", """$file"""
        "-c", "ass"
        """$srtFileName"""
    );
    Start-Process ffmpeg `
        -ArgumentList $arguments `
        -Wait -NoNewWindow -PassThru;
};

timeout.exe 15;
