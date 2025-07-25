Extension-Communicator.ps1 -LogPath "$PSScriptRoot\Logs.txt" -MessageHandler {
    param(
        $Data
    )
    $action = $Data.action;
    switch ($action) {
        "Save-Torrent" {
            $link = $Data.link;
            $title = $Data.title -replace '[<>:"/\\|?*]', '';
            $command = "& { 
                    `$saveLocation = Folder-Picker.ps1 -Retry 1 -ShowOnTop;
                    Create-Shortcut.ps1 -Target (`$saveLocation + '\$title.url') -Source '$link';
            }"
            Start-Process pwsh.exe -ArgumentList @(
                "-Command", $command
            );
            break;
        }

        "Download-Video" {
            $link = $Data.link;
            Start-Process pwsh.exe -ArgumentList @(
                "-Command", "Youtube-Downloader.ps1 -Link $link -Format opus"
            )
            break;
        }

        "Subtitle-Download" {
            $Source = $Data.source;
            $downloadLink = $Data.downloadLink;
            $generalInfo = $Data.generalInfo;
            $savePath = $Data.savePath;
            $renameTo = $Data.renameTo;
            Start-Process pwsh.exe -ArgumentList @(
                "-Command", "Subtitles-Downloader.ps1 -Title '$title' -Season '$season' -Episodes '$episodes' -Year '$year' -SavePath '$savePath' -RenameTo '$renameTo'"
            )
            break;
        }
    }
}