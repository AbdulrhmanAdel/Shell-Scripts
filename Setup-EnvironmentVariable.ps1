[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $NoTimeout
)

$ModuleName = "ShellScripts";
$ModuleGuid = "8f3a6d21-4c7b-4f5e-9a02-6d1b8e4c7a93";

[System.Environment]::SetEnvironmentVariable("Shell-Scripts", $PSScriptRoot, "User");

Import-Module "$PSScriptRoot\$ModuleName.psm1" -Force;
$commands = @((Get-Module $ModuleName).ExportedFunctions.Keys | Sort-Object);
Remove-Module $ModuleName -Force;

if ($commands.Count -eq 0) {
    Write-Host "No commands discovered, aborting." -ForegroundColor Red;
    Exit;
}

New-ModuleManifest -Path "$PSScriptRoot\$ModuleName.psd1" `
    -RootModule "$ModuleName.psm1" `
    -ModuleVersion "1.0.0" `
    -Guid $ModuleGuid `
    -Description "Shared commands for the Shell-Scripts repository." `
    -PowerShellVersion "7.0" `
    -FunctionsToExport $commands `
    -CmdletsToExport @() `
    -VariablesToExport @() `
    -AliasesToExport @();

Write-Host "Generated manifest with $($commands.Count) commands." -ForegroundColor Green;

$modulesRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "PowerShell\Modules";
$linkPath = Join-Path $modulesRoot $ModuleName;
New-Item -Path $modulesRoot -ItemType Directory -Force | Out-Null;

$existing = Get-Item -LiteralPath $linkPath -ErrorAction SilentlyContinue;
if ($existing -and $existing.LinkType) {
    [System.IO.Directory]::Delete($linkPath, $false);
}
elseif ($existing) {
    Write-Host "$linkPath exists and is not a link, remove it manually." -ForegroundColor Red;
    Exit;
}

New-Item -Path $linkPath -Target $PSScriptRoot -ItemType Junction | Out-Null;
Write-Host "Linked $linkPath -> $PSScriptRoot" -ForegroundColor Green;

$legacyPath = "$PSScriptRoot\.path";
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User");
$paths = @($currentPath -split ";" | Where-Object { $_ -and $_.TrimEnd('\') -ne $legacyPath });
$paths = @($paths) + @("$PSScriptRoot\Updaters\Apps") | Select-Object -Unique;
[System.Environment]::SetEnvironmentVariable("Path", $paths -join ";", "User");

if (Test-Path -LiteralPath $legacyPath) {
    Remove-Item -LiteralPath $legacyPath -Force -Recurse;
    Write-Host "Removed legacy .path folder." -ForegroundColor Green;
}

Write-Host "$ModuleName is available in every new PowerShell session." -ForegroundColor Green;
if ($NoTimeout) {
    Exit;
}

timeout 5;
