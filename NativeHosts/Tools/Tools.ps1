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
                    `$fileName = '$title.url';
                    `$saveLocation = Folder-Picker.ps1 -Retry 1 -ShowOnTop;
                    `$userFolderNameAsTitle=Prompt.ps1 -Message 'Do you want to use folder name as File name';
                    if (`$userFolderNameAsTitle) {
                        `$fileName = Split-Path -Leaf `$saveLocation;
                        `$fileName = `$fileName + '.url'
                    }
                    Create-Shortcut.ps1 -Target (`$saveLocation + '\' + `$fileName) -Source '$link';
                    timeout 5;
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
            $command = "& {
                Subtitles-Downloader.ps1 -Title '$title' -Season '$season' -Episodes '$episodes' -Year '$year' -SavePath '$savePath' -RenameTo '$renameTo'
            }"
            Start-Process pwsh.exe -ArgumentList @(
                "-Command", $command
            );
            break;
        }
    }
}