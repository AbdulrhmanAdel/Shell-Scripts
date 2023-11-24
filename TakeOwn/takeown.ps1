$folderName = $args[0];
$git = $args[1] -eq 'git';

$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = "powershell"

if ($git) {
    $processInfo.Arguments = "-File ""D:\Programs\Shell-Scripts\TakeOwn\fix-git-owner-ship.ps1"" ""$folderName""";
} 
else {
    $processInfo.Arguments = "-File ""D:\Programs\Shell-Scripts\TakeOwn\normal-take.ps1"" ""$folderName""";
}

$processInfo.Verb = "RunAs"

# Start the new process
[System.Diagnostics.Process]::Start($processInfo)
