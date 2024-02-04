$folderName = $args[0];
$runningFilePath = $PSCommandPath;
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Read-Host "PRESS any key to continue."
    Start-Process Powershell -Verb RunAs "-File $runningFilePath ""$folderName""";
    exit;
}

$fileInfo = Get-Item -LiteralPath $folderName;
$takeOwn = "TakeOwn";
if ($fileInfo -is [System.IO.FileInfo]) {
    &$takeOwn /f "$folderName"
}
else {
    $gitPath = "$folderName\.git";
    if (Test-Path -LiteralPath $gitPath) {
        &$takeOwn /f "$folderName"
        $folderName = $gitPath;
    }
    &$takeOwn /f "$folderName" /r /d y
}

Write-Output "TakeDown finished for $folderName"
Write-Output "EXITING IN 5S"
Start-Sleep -Seconds 5
