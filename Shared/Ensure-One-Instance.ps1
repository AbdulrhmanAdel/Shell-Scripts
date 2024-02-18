# $lockFilePath = ($PSScriptRoot + "/" + $MyInvocation.MyCommand.Name).Replace('.ps1', '.lock');
$textFilePath = ($PSScriptRoot + "/" + $MyInvocation.MyCommand.Name).Replace('.ps1', '.txt');
$arg = $args[0];
if (
    Test-Path $textFilePath) { 
    Add-Content -Path "$textFilePath" -Value "$($arg)";
    exit;
}
else {
    New-Item -Path $textFilePath -ItemType File -Force | Out-Null;
    Add-Content -Path "$textFilePath" -Value "$($arg)";
    Write-Host "Waiting for data";
    Start-Sleep -Seconds 5;
    
    $content = Get-Content -LiteralPath $textFilePath;
    Remove-Item -LiteralPath $textFilePath;
    return $content;
}


# $pipeName = "Test"
# if (Test-Path $lockFilePath) {
#     Write-Host "Another instance is already running."
#     try {
#         $client = New-Object System.IO.Pipes.NamedPipeClientStream(".", $pipeName);
#         $client.Connect();
#         $writer = New-Object System.IO.StreamWriter($client, [System.Text.Encoding]::UTF8);
#         $writer.WriteLine("10");
#         $writer.Flush();
#         $writer.Dispose();
#         $client.Dispose();
#     }
#     catch {
#         Write-Error "Error connecting to named pipe server: $_"
#     }
#     exit
# }

# # Create a lock file to signal that this instance is running
# New-Item -Path $lockFilePath -ItemType File;
# try {
#     $server = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName);
#     $server.WaitForConnection();
#     $reader = New-Object System.IO.StreamReader($server, [System.Text.Encoding]::UTF8);
#     Start-Sleep -Seconds 25;
#     while ($reader.Peek() -ge 0) {
#         $message = $reader.ReadLine();
#         Write-Host $message;
#     }
    
#     Read-Host "DONE"
#     $reader.Dispose();
#     $server.Dispose();
#     Remove-Item -LiteralPath $lockFilePath;
# }
# catch {
#     Write-Error "Error creating named pipe server: $_"
# }

# # Keep the script alive until the user decides to close it
