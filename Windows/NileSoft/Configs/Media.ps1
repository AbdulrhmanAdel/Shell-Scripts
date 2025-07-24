return @(
    @{
        Title    = "Media"
        Target   = "file|dir"
        Filter   = ".mp3|.m4a|.opus|.mp4|.mkv|.zip|.rar"
        Children = @(
            @{
                Target   = "file"
                Filter   = ".mp3|.m4a|.opus|.mp4|.mkv"
                Title    = "Crop"
                FilePath = "$ShellScripsPath\Media\Crop.ps1"
            }
            @{
                Target   = "file|dir"
                Filter   = ".mp4|.mkv|.zip|.rar"
                Title    = "Remove Unused Tracks"
                FilePath = "$ShellScripsPath\Media\Remove-UnusedTracks.ps1"
            }
            @{
                Target   = "file"
                Filter   = ".mkv|.mp4"
                Title    = "Display Chapters Info"
                FilePath = "$ShellScripsPath\Media\Display-ChaptersInfo.ps1"
            }
        )
    }
);