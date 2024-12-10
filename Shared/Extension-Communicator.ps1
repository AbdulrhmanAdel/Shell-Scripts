[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [scriptblock]
    $MessageHandler,
    [Parameter()]
    [string]
    $LogPath = "$PSScriptRoot\Logs.txt"
)

if (Test-Path -LiteralPath $LogPath) {
    Clear-Content -LiteralPath $LogPath;
}
else {
    New-Item -Path $LogPath;
}

function Log {
    param (
        $text
    )

    Add-Content -LiteralPath $LogPath -Value $text;
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


while ($true) { 
    try {
        $json = Read-Message;
        Log -text "=======================";
        Log -text $json;
        if ($null -eq $json) {
            break  # Exit the loop if there is an error or end of input stream.
        }

        $MessageHandler.Invoke($json);
    }
    catch {
        Add-Content "Error.txt" $_.ScriptStackTrace;
        EXIT;
    }
    Log -text "=======================";
    Log -text "";
}
