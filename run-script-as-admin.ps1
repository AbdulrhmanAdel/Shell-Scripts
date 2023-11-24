$folderName = $args[0];
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = "powershell"
$processInfo.Arguments = "-Command  TakeOwn /f '$folderName' /r"
$processInfo.Verb = "RunAs"
    
# Start the new process
$process = [System.Diagnostics.Process]::Start($processInfo)
$process.WaitForExit();
Write-Host "Press any key to exit..."
