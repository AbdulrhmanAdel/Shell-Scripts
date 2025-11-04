[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $NoTimeout
)

[System.Environment]::SetEnvironmentVariable("Shell-Scripts", $PSScriptRoot, "User");

$TargetFolder = "$PSScriptRoot\.path";
if (Test-Path -LiteralPath $TargetFolder) {
    Remove-Item -LiteralPath $TargetFolder -Force -Recurse -ErrorAction SilentlyContinue;
    New-Item -Path $TargetFolder -ItemType Directory -Force;
}
else {
    New-Item -Path $TargetFolder -ItemType Directory -Force;
}

$sharedPath = "$PSScriptRoot\Shared";
$SourceFoldersAndFiles = @(
    $sharedPath, 
    @{
        Path = "$PSScriptRoot\Youtube\Downloader.ps1";
        Name = "Youtube-Downloader.ps1"
    }
);

Get-ChildItem -Path $sharedPath -Directory -Recurse | Where-Object {
    if ($_.FullName -notmatch "Ignore|Modules") {
        $SourceFoldersAndFiles += $_;
    }
} 

Write-Host $SourceFoldersAndFiles;
$SourceFoldersAndFiles | ForEach-Object {
    $itemInfo = Get-Item -LiteralPath ($_.Path ?? $_);
    if ($itemInfo -is [System.IO.DirectoryInfo]) {
        Get-ChildItem -Path $_ -File | ForEach-Object {
            New-Item `
                -Path "$TargetFolder\$($_.Name)" `
                -Target $_.FullName `
                -ItemType SymbolicLink ;
        }
        return;
    }

    $targetName = $_.Name ?? $itemInfo.Name;
    New-Item `
        -Path "$TargetFolder\$targetName" `
        -Target $itemInfo.FullName `
        -ItemType SymbolicLink;
}

# Current system path
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User");
$DirectPaths = @(
    $TargetFolder,
    "$PSScriptRoot\Updaters\Apps"
);

$paths = $currentPath -split ";";
$newPaths += $DirectPaths;
$newPaths = $newPaths | Select-Object -Unique
if ($paths.Length -eq $newPaths.Length) {
    Write-Host "Finished adding shared paths to the user environment variable." -ForegroundColor Green;
	
timeout 5;

    Exit;
}

[System.Environment]::SetEnvironmentVariable("Path", $newPaths -join ";", "User");
Write-Host "Finished adding shared paths to the user environment variable." -ForegroundColor Green;
if ($NoTimeout) {
    Exit;
}
timeout 5;
