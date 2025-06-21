function Send-Response {
    param ($response)

    $responseJson = $response | ConvertTo-Json
    $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
    $responseLengthBytes = [BitConverter]::GetBytes($responseBytes.Length)
    $stdout.Write($responseLengthBytes, 0, 4)
    $stdout.Write($responseBytes, 0, $responseBytes.Length)
}

function DownloadImage {
    param (
        $imageUrl
    )
    
    $tempFilePath = "$($env:TEMP)\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').png";
    if (Test-Path -LiteralPath $tempFilePath) {
        if (-not (Read-Host "Do you want to Use Image From Cache?")) {
            return $tempFilePath;
        }

        Remove-Item -LiteralPath $tempFilePath -Force
    }

    $tempImage = New-Item "$tempFilePath"; 
    Invoke-WebRequest -UseBasicParsing -uri $imageUrl -outfile $tempFilePath;
    return $tempImage.FullName;
}

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
    }
}