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

Extension-Communicator.ps1 -MessageHandler {
    param(
        $Data
    )

    switch ($Data.action) {
        'Youtube' { 
            & "D:\Programming\Projects\Personal Projects\Shell-Scripts\Youtube\Downloader.ps1" -Link $Data.link
        }
        Default {
            Set-Content "Test.txt" $Data;
        }
    }
}