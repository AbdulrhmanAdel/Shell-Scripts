Write-Host "Downloading New Visual Studio Code Version" -ForegroundColor Green;

$DownloadUrl = 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-archive';
$DownloadPath = "$env:TEMP\vscode.zip";
if (-not (Test-Path -LiteralPath $DownloadPath)) {
    Invoke-WebRequest $DownloadUrl -OutFile $DownloadPath;
}

Write-Host "Remove Old Visual Studio Code" -ForegroundColor Green;
Stop-Process -Name Code -Force -ErrorAction SilentlyContinue;   
$Destination = [System.Environment]::GetEnvironmentVariable("VsCodePath", "User") ?? (Folder-Picker.ps1 -InitialDirectory "D:\"); 
if (Test-Path -LiteralPath $Destination) {
    Remove-Item -LiteralPath $Destination -Force -Recurse;
}

Write-Host "Extracting Visual Studio Code" -ForegroundColor Green;
$archiveProcess = Start-Process 7z.exe -ArgumentList @(
    "x", 
    """$DownloadPath""",
    "-o$Destination"
) -NoNewWindow -PassThru -Wait;
    
if (!$archiveProcess -or $archiveProcess.ExitCode -gt 0) {
    Write-Host "Failed to extract Visual Studio Code" -ForegroundColor Red;
    Invoke-Item $DownloadPath;
}
else {
    Stop-Process -Id $archiveProcess.Id;
    Write-Host "Visual Studio Code Updated Successfully" -ForegroundColor Green;
    Write-Host "Removing Download Zip file" -ForegroundColor Green;
    Remove-Item -Path "$Destination\locales" -Exclude "en-US.pak" -Force -Recurse;
    Remove-Item -LiteralPath $DownloadPath -Force;
}

timeout.exe 15;

