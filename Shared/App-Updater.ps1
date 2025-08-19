[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $ProcessName, 
    [string]
    $DownloadUrl,
    [string]
    $AppPath,
    [string[]]
    $KeepFiles,
    [ValidateSet("Normal", "Electron")]
    [string]
    $ArchiveType = "Normal",
    $Cleaner
)
$Cleaner ??= {
    
}

Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue;   
$DownloadUrl ??= Input.ps1 -Title "Enter the Download URL" -DefaultValue -Required;
$AppPath ??= Folder-Picker.ps1 -InitialDirectory "D:\" -Required;
$AppName = $ProcessName;

Write-Host "Remove Old $AppName" -ForegroundColor Green;
if (Test-Path -LiteralPath $AppPath) {
    if ($null -ne $KeepFiles) {
        Get-ChildItem -LiteralPath $AppPath | Foreach-Object {
            if ($_.Name -ne $KeepFiles) {
                Remove-Item -LiteralPath $_.FullName -Force -Recurse;
            }
        }
    }
    else {
        Remove-Item -LiteralPath $AppPath -Force -Recurse;
    }
}

$DownloadPath = "$env:TEMP\$AppName.zip";
if (-not (Test-Path -LiteralPath $DownloadPath)) {
    Write-Host "Downloading New $AppName Version" -ForegroundColor Green;
    Invoke-WebRequest $DownloadUrl -OutFile $DownloadPath;
}

Write-Host "Extracting $AppName" -ForegroundColor Green;
if ($ArchiveType -eq "Electron") {
    $Destination = "$env:TEMP\$ProcessName-$(Get-Date -Format 'yyyyMMdd-HHmmss')";
    Start-Process 7z -ArgumentList @(
        "x", 
        """$DownloadPath""",
        "-o$Destination"
    ) -NoNewWindow -PassThru -Wait;
    $DownloadPath = "$Destination\$('$PLUGINSDIR')\app-64.7z";
}

$archiveProcess = Start-Process 7z -ArgumentList @(
    "x", 
    """$DownloadPath""",
    "-o$AppPath"
) -NoNewWindow -PassThru -Wait;
    
if (!$archiveProcess -or $archiveProcess.ExitCode -gt 0) {
    Write-Host "Failed to extract $AppName" -ForegroundColor Red;
    Invoke-Item $DownloadPath;
}
else {
    Write-Host "$AppName Updated Successfully" -ForegroundColor Green;
    Write-Host "Removing Download Zip file" -ForegroundColor Green;
    Remove-Item -LiteralPath $DownloadPath -Force;
}

timeout.exe 15;