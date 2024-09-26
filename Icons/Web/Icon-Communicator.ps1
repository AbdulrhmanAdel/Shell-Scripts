# Open standard input and output streams.
$logFilePath = "$($PSScriptRoot)/Log.txt";
Clear-Content -LiteralPath $logFilePath;
function Log {
    param (
        $text
    )

    Add-Content -LiteralPath $logFilePath -Value $text;
}

$stdin = [Console]::OpenStandardInput()
$stdout = [Console]::OpenStandardOutput()

#region Functions
# Function to read a message from stdin and process it.
function Read-Message {
    $lengthBytes = [byte[]]::new(4)
    $bytesRead = $stdin.Read($lengthBytes, 0, 4)
    if ($bytesRead -ne 4) {
        return $null  # Signal end of stream or error.
    }

    $length = [BitConverter]::ToInt32($lengthBytes, 0)
    $messageBytes = [byte[]]::new($length)
    $bytesRead = $stdin.Read($messageBytes, 0, $length)
    if ($bytesRead -ne $length) {
        return $null  # Signal end of stream or error.
    }

    $text = [System.Text.Encoding]::UTF8.GetString($messageBytes);
    if (!$text) {
        return $null;
    }
    return  $text | ConvertFrom-Json;
}

# Function to send a response back to the Chrome extension.
function Send-Response {
    param ($response)

    $responseJson = $response | ConvertTo-Json
    $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
    $responseLengthBytes = [BitConverter]::GetBytes($responseBytes.Length)
    $stdout.Write($responseLengthBytes, 0, 4)
    $stdout.Write($responseBytes, 0, $responseBytes.Length)
}


function DonwloadImage {
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

function IsGameFolder {
    param (
        $folderPath
    )
    

    return Test-Path -Path "$folderPath/*" -Include @("setup*.exe", "install*.exe");
}

function GetFolders {
    param ($directoryPath = "G:\Games")
    return Get-ChildItem -Path $directoryPath -Directory -Recurse | Where-Object {
        $isGame = IsGameFolder -folderPath $_.FullName
        $isCollection = $_.Name -match "Collection|Series";
        if (!$isGame -and !$isCollection) {
            return $false;
        }

        return !(Test-Path -LiteralPath "$($_.FullName)\desktop.ini");
    }
}
#endregion

function HandleFolder {
    if ($global:folders.Length -eq 0) {
        return;
    }

    $local:folder , $global:folders = $global:folders;
    Send-Response -response @{
        action     = "process"
        folderName = ($local:folder.Name -replace " ?((\[|\().*(\]|\)))", "")
        folderPath = $local:folder.FullName
    }
}

# $global:folders = GetFolders -directoryPath "G:\Games";
# if ($global:folders.Length -eq 0) {
#     Send-Response -response @{
#         action = "no-folders"
#     }
#     EXIT;
# }

# Send-Response -response @{
#     action  = "folders"
#     folders = @($global:folders | ForEach-Object { return $_.FullName })
# }

# HandleFolder;
while ($true) { 
    try {
        $json = Read-Message;
        Log -text "=======================";
        Log -text $json;
        if ($null -eq $json) {
            break  # Exit the loop if there is an error or end of input stream.
        }

        $action = $json.action;
        switch ($action) {
            "icon" {
                $folder = $json.folderPath;
                $imgLink = $json.imgLink;
                $imgPath = DonwloadImage -imageUrl $imgLink;
                $setFolderIconScriptPath = "D:\Programming\Projects\Personal Projects\Shell-Scripts\Icons\Set-Folder-Icon.ps1";
                Start-Process pwsh.exe -ArgumentList @('-File', """$setFolderIconScriptPath""", '-ImagePath', """$imgPath""" , '-DirectoryPath', """$folder""", '-SkipTimeout')
                # HandleFolder;
                break;
            }
            "next" {
                # HandleFolder;
            }
        }
    }
    catch {
        Add-Content "Icons.txt" $_.ScriptStackTrace;
        EXIT;
    }
    Log -text "=======================";
    Log -text "";
}
