[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $NoTimeout
)

$parentDirectory = "$PSScriptRoot\Shared"
$TargetFolder = "$PSScriptRoot\.path";
if (-not (Test-Path -LiteralPath $TargetFolder)) {
    New-Item -Path $TargetFolder -ItemType Directory | Out-Null;
}

Get-ChildItem -Path $parentDirectory -File | ForEach-Object {
    New-Item `
        -Path "$TargetFolder\$($_.Name)" `
        -Target $_.FullName `
        -ItemType SymbolicLink -ErrorAction SilentlyContinue;
    
}

# Retrieve all directory paths
Get-ChildItem -Path $parentDirectory -Directory -Recurse | Where-Object {
    return $_.FullName -notmatch "Ignore|Modules"
} | Select-Object -ExpandProperty FullName | ForEach-Object {
    Get-ChildItem -Path $_ -File | ForEach-Object {
        New-Item `
            -Path "$TargetFolder\$($_.Name)" `
            -Target $_.FullName `
            -ItemType SymbolicLink -ErrorAction SilentlyContinue;
    }
}

# Current system path
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User");
$paths = $currentPath -split ";";

if ($paths.Contains($TargetFolder)) {
    Write-Host "Finished adding shared paths to the user environment variable." -ForegroundColor Green;
    Exit;
}
$paths += $TargetFolder;
[System.Environment]::SetEnvironmentVariable("Path", $paths -join ";", "User");
Write-Host "Finished adding shared paths to the user environment variable." -ForegroundColor Green;
if ($NoTimeout) {
    Exit;
}
timeout 5;
