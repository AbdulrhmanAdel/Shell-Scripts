Extension-Communicator.ps1 -LogPath "$PSScriptRoot\Logs.txt" -MessageHandler {
    param(
        $Data
    )
    $action = $Data.action;
    switch ($action) {
        "Save-Torrent" {
            $link = $Data.link;
            $title = $Data.title -replace '[<>:"/\\|?*]', '';
            $saveLocation = Folder-Picker.ps1 -Retry 1 -ShowOnTop;
            Create-Shortcut.ps1 -Source $link  -Target "$saveLocation\$title.url";
            break;
        }

        "Download-Video" {
            $link = $Data.link;
            $scriptPath = Resolve-Path -Path "$PSScriptRoot\..\..\Youtube\Downloader.ps1"
            Start-Process pwsh.exe  -WindowStyle Maximized -ArgumentList @(
                "-File", """$scriptPath""",
                "-Link", $link,
                "-Format", "opus"
            )
            break;
        }
    }
}