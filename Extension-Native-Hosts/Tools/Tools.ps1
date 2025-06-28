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
    }
}