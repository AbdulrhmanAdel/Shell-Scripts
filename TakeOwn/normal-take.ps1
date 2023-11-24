$folderName = $args[0];
$isDirectroy = (Get-Item -LiteralPath $folderName) -is [System.IO.DirectoryInfo];

$command = "TakeOwn";
Write-Host "$folderName";
Write-Host "isDirectroy $isDirectroy";



if ($isDirectroy) {
    $command += " /f ""$folderName"" /r /d y"
}
else {
    $command += " /f ""$folderName"""
}
Write-Output "Command $command"
Write-Output "STARTING IN 5S"
Start-Sleep -Seconds 5
$processInfo = New-Object System.Diagnostics.ProcessStartInfo;
$processInfo.FileName = "powershell";
$processInfo.Arguments = "-Command  $command";
$processInfo.UseShellExecute = $false;
[System.Diagnostics.Process]::Start($processInfo)
Write-Output "EXITING IN 5S"
Start-Sleep -Seconds 5
