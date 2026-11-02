[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $NoTimeout
)

$ModuleName = "ShellScripts";

[System.Environment]::SetEnvironmentVariable("Shell-Scripts", $PSScriptRoot, "User");

Import-Module "$PSScriptRoot\$ModuleName.psm1" -Force -DisableNameChecking;
$commands = @(Update-ShellScriptsManifest);
Remove-Module $ModuleName -Force;

if ($commands.Count -eq 0) {
    Write-Host "No commands discovered, aborting." -ForegroundColor Red;
    Exit;
}

Write-Host "Generated manifest with $($commands.Count) commands." -ForegroundColor Green;

$modulesRoot = $IsLinux ? (Join-Path $HOME '.local/share/powershell/Modules') : (Join-Path ([Environment]::GetFolderPath('MyDocuments')) "PowerShell\Modules");
$linkPath = Join-Path $modulesRoot $ModuleName;
New-Item -Path $modulesRoot -ItemType Directory -Force | Out-Null;

$existing = Get-Item -LiteralPath $linkPath -ErrorAction SilentlyContinue;
if ($existing -and $existing.LinkType) {
    if ($IsLinux) {
        Remove-Item -LiteralPath $linkPath -Force;
    }
    else {
        [System.IO.Directory]::Delete($linkPath, $false);
    }
}
elseif ($existing) {
    Write-Host "$linkPath exists and is not a link, remove it manually." -ForegroundColor Red;
    Exit;
}

New-Item -Path $linkPath -Target $PSScriptRoot -ItemType ($IsLinux ? 'SymbolicLink' : 'Junction') | Out-Null;
Write-Host "Linked $linkPath -> $PSScriptRoot" -ForegroundColor Green;

if ($IsLinux) {
    # Same PATH entry as below. A symlink to Updater.ps1 is not enough, $PSScriptRoot would be the link's folder.
    $appsPath = "$PSScriptRoot/Updaters/Apps";
    # Apps started from the menu and every terminal, after the next login. The name must sort after Ubuntu's 99-environment.conf
    $environmentDir = Join-Path $HOME '.config/environment.d';
    New-Item -ItemType Directory -Force $environmentDir | Out-Null;
    Set-Content -LiteralPath (Join-Path $environmentDir '999-shell-scripts.conf') -Value "PATH=${appsPath}:`${PATH}";

    # Login shells (a text console, ssh)
    $profilePath = Join-Path $HOME '.profile';
    $marker = '# Shell-Scripts updaters (Setup-EnvironmentVariable.ps1)';
    $lines = @((Test-Path -LiteralPath $profilePath) ? (Get-Content -LiteralPath $profilePath) : @());
    $lines = @($lines | Where-Object { $_ -ne $marker -and $_ -notmatch '/Updaters/Apps:' });
    Set-Content -LiteralPath $profilePath -Value $lines;
    Add-Content -LiteralPath $profilePath -Value @($marker, "case `":`$PATH:`" in *`":${appsPath}:`"*) ;; *) PATH=`"${appsPath}:`$PATH`" ;; esac");

    Write-Host "$ModuleName and Updater.ps1 are available after the next login." -ForegroundColor Green;
    Exit;
}

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
