# Get the script path from the first argument
if ($args.Count -eq 0) {
    Write-Host "Please provide the path to the script as the first argument."
    exit
}

$scriptPath = $args[0]
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)

# Set the path for the text file on the D: drive
$textFilePath = "$($env:TEMP)\$scriptName.txt"

# Retry creating or appending to the file until successful

if (-not (Test-Path -Path $textFilePath)) {
    # Try to create the text file and write the initial content
    try {
        Add-Content -Path $textFilePath -Value "Created by script: $scriptPath"
    }
    catch {
        throw "Error creating file: $($_.Exception.Message)"
    }
}
else {
    # Try to append content if the file already exists
    try {
        Add-Content -Path $textFilePath -Value "Appended by script: $scriptPath"
    }
    catch {
        throw "Error appending to file: $($_.Exception.Message)"
    }
    EXIT;
}

# Retry opening the text file in the default text editor until successful

try {
    Start-Process -FilePath "notepad.exe" -ArgumentList $textFilePath
}
catch {
    throw "Error opening the file in the editor: $($_.Exception.Message)"
}

