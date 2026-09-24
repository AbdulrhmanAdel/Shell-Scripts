[CmdletBinding()]
param (
    $CurrentVersion,
    $Downloader,
    $Cleaner,
    $Installer,
    # Files kept across the update, e.g. a settings.ini the new version would overwrite with its own
    [string[]]$Preserve,
    # No prompts: update, close the running app and restart it afterwards. Also on with $env:APP_UPDATER_SILENT=1
    [switch]$Silent,
    # Only look up the latest version, download and change nothing. Also on with $env:APP_UPDATER_CHECK_ONLY=1
    [switch]$CheckOnly
)

$Silent = $Silent -or $env:APP_UPDATER_SILENT -eq '1';
$CheckOnly = $CheckOnly -or $env:APP_UPDATER_CHECK_ONLY -eq '1';

#region Helpers

function ExecuteScript {
    param (
        $Item,
        $Path,
        $AdditionalArgs = @{}
    )

    if (!$Item -or !$Item.Name) {
        Write-Host "[WARN] No $Item for $Path specified. Skipping." -ForegroundColor DarkGray
        return $null;
    }

    $finalArgs = $AdditionalArgs + $Item.Args;
    return & "$PSScriptRoot\$Path\$($Item.Name)" @finalArgs;
}

# Status: Updated | UpToDate | UpdateAvailable | Skipped | Failed
function New-Result {
    param (
        [string]$Status,
        [string]$Message
    )

    # The staging copy is only needed during the install, whatever the outcome
    if ($stagingPath) {
        Remove-Item -LiteralPath $stagingPath -Recurse -Force -ErrorAction SilentlyContinue;
    }
    if ($Message) {
        $color = @{ Failed = 'Red'; Skipped = 'Yellow' }[$Status] ?? 'Gray';
        Write-Host "$($Status -eq 'Failed' ? '[ERROR]' : '[INFO]') $Message" -ForegroundColor $color;
    }
    return @{
        Success    = $Status -eq 'Updated'
        Status     = $Status
        Name       = $appName
        OldVersion = $oldVersion
        NewVersion = $newVersion
        Message    = $Message
        Running    = @($script:runningNames)
        Restarted  = @($script:restarted)
    }
}

function Confirm-Step {
    param (
        [string]$Message,
        [bool]$Default = $true
    )

    if ($Silent) {
        return $Default;
    }
    return Prompt.ps1 -Title "App Updater - $appName" -Message $Message -DefaultValue $Default;
}

# Mandatory parameters of a step script that are not supplied, so it fails here instead of prompting mid-update
function Get-MissingArgs {
    param (
        $Item,
        $Path,
        $AdditionalArgs = @{}
    )

    $command = Get-Command "$PSScriptRoot\$Path\$($Item.Name).ps1" -ErrorAction SilentlyContinue;
    $command ??= Get-Command "$PSScriptRoot\$Path\$($Item.Name)" -ErrorAction SilentlyContinue;
    if (!$command) {
        return @("<script $Path\$($Item.Name) not found>");
    }

    $supplied = @($AdditionalArgs.Keys) + @($Item.Args.Keys);
    return @($command.Parameters.Values | Where-Object {
            $_.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }
        } | Where-Object { $supplied -notcontains $_.Name } | ForEach-Object { $_.Name });
}

# Processes running from one of the folders
function Get-AppProcesses {
    param ([string[]]$Folders)

    $Folders = @($Folders | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | ForEach-Object { (Resolve-Path -LiteralPath $_).Path.TrimEnd('\') + '\' });
    if (!$Folders) {
        return @();
    }

    # Elevated processes hide their path from a normal shell, so also match by the exe names found in the folders
    $exeNames = @($Folders | ForEach-Object { Get-ChildItem -LiteralPath $_ -Filter *.exe -Recurse -Depth 2 -File -ErrorAction SilentlyContinue } | ForEach-Object { $_.Name }) | Sort-Object -Unique;
    return @(Get-CimInstance Win32_Process | Where-Object {
            $path = $_.ExecutablePath;
            ($path -and ($Folders | Where-Object { $path.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) })) -or
            (!$path -and $exeNames -contains $_.Name)
        });
}

# This updater and the shells that started it (e.g. updating PowerShell from PowerShell)
function Get-OwnProcessIds {
    $processes = @(Get-CimInstance Win32_Process);
    $ids = @();
    $current = $processes | Where-Object ProcessId -eq $PID;
    while ($current -and $ids -notcontains $current.ProcessId) {
        $ids += $current.ProcessId;
        $current = $processes | Where-Object ProcessId -eq $current.ParentProcessId;
    }
    return $ids;
}

# The command line minus the exe, so the app can be restarted the way it was started
function Get-ProcessArguments {
    param ($Process)

    $commandLine = "$($Process.CommandLine)".Trim();
    if ($commandLine.StartsWith('"')) {
        $end = $commandLine.IndexOf('"', 1);
        return $end -gt 0 ? $commandLine.Substring($end + 1).Trim() : '';
    }
    if ($Process.ExecutablePath -and $commandLine.StartsWith($Process.ExecutablePath, [StringComparison]::OrdinalIgnoreCase)) {
        return $commandLine.Substring($Process.ExecutablePath.Length).Trim();
    }
    return ($commandLine -split '\s+', 2)[1];
}

function Restart-ClosedApps {
    if (!$script:toRestart) {
        return;
    }

    $names = ($script:toRestart | ForEach-Object { Split-Path $_.Path -Leaf }) -join ', ';
    if (!(Confirm-Step "Restart $names?")) {
        return;
    }
    foreach ($app in $script:toRestart) {
        if (!(Test-Path -LiteralPath $app.Path)) {
            continue;
        }
        $startArgs = @{ FilePath = $app.Path; WorkingDirectory = (Split-Path $app.Path) };
        if ($app.Arguments) {
            $startArgs.ArgumentList = $app.Arguments;
        }
        Start-Process @startArgs;
        $script:restarted += Split-Path $app.Path -Leaf;
        Write-Host "[INFO] Restarted $(Split-Path $app.Path -Leaf)" -ForegroundColor DarkGray;
    }
}

#endregion

$script:runningNames = @();
$script:restarted = @();
$script:toRestart = @();

$CurrentVersionDetails = $CurrentVersion.Name -eq "Direct" ? $CurrentVersion.Args : (ExecuteScript -Path "Details" -Item $CurrentVersion);
# Shims cd into the app folder, so its name is a good label when the updater does not give one
$appName = $CurrentVersionDetails.Name ?? (Split-Path (Get-Location) -Leaf);
$oldVersion = $CurrentVersionDetails.Version;
$newVersion = $null;
$stagingPath = $null;

$appFolders = @(@($Cleaner.Args.Paths) + @($Installer.Args.Destination) | Where-Object { $_ } | ForEach-Object {
        (Test-Path -LiteralPath $_ -PathType Leaf) ? (Split-Path $_) : $_
    });

#region Check

Write-Host "Starting update process for $appName" -ForegroundColor Green;
Write-Host "===================== Download =====================" -ForegroundColor Green;
$downloaderArtifacts = ExecuteScript -Path "Downloaders" -AdditionalArgs @{
    CurrentVersion = $oldVersion
    CheckOnly      = $CheckOnly
} -Item $Downloader;
Write-Host "===================== End Download =====================" -ForegroundColor Green;
$newVersion = $downloaderArtifacts.LatestVersion;

if (!$downloaderArtifacts.HasNewVersion) {
    if ($downloaderArtifacts.Message) {
        return New-Result 'Failed' $downloaderArtifacts.Message;
    }
    Write-Host "No new version found for $appName. Current $oldVersion; Latest $newVersion.";
    return New-Result 'UpToDate';
}

if ($CheckOnly) {
    $script:runningNames = @(Get-AppProcesses -Folders $appFolders | ForEach-Object { $_.Name } | Sort-Object -Unique);
    if ($downloaderArtifacts.Message) {
        return New-Result 'Failed' $downloaderArtifacts.Message;
    }
    return New-Result 'UpdateAvailable' "$appName $oldVersion -> $newVersion";
}

# APP_UPDATER_CONFIRMED: the caller (e.g. the software updater's picker) already asked
if ($env:APP_UPDATER_CONFIRMED -ne '1' -and !(Confirm-Step "$appName $oldVersion -> $($newVersion ?? 'new version'). Update now?")) {
    return New-Result 'Skipped' "Update skipped.";
}

#endregion

#region Safety checks: nothing has been touched yet, so any failure here leaves the app as it was

$downloadPath = $downloaderArtifacts.DownloadPath;
if ($downloaderArtifacts.Message) {
    return New-Result 'Failed' "$($downloaderArtifacts.Message). Nothing was cleaned.";
}
if (!$downloadPath -or !(Test-Path -LiteralPath $downloadPath) -or (Get-Item -LiteralPath $downloadPath).Length -eq 0) {
    return New-Result 'Failed' "Download failed ('$downloadPath'). Nothing was cleaned.";
}

$missing = @(Get-MissingArgs -Path "Installers" -Item $Installer -AdditionalArgs @{ Path = $downloadPath });
if ($missing) {
    return New-Result 'Failed' "Installer '$($Installer.Name)' is missing required args: $($missing -join ', '). Nothing was cleaned.";
}

if ($Installer.Name -eq "Archive") {
    & 7z t $downloadPath | Out-Null;
    if ($LASTEXITCODE -ne 0) {
        Remove-Item -LiteralPath $downloadPath -Force -ErrorAction SilentlyContinue;
        return New-Result 'Failed' "Downloaded archive is corrupt, deleted it: $downloadPath. Nothing was cleaned.";
    }
}

# The updater's exe must exist after installing, otherwise the install silently did nothing
$exePath = $CurrentVersion.Name -eq "Properties" ? $CurrentVersion.Args.Path : $null;
$destination = $Installer.Args.Destination;

# Archive/Copy installs go to a staging folder first, so a wrong asset or archive layout is caught before cleaning
$stagingPath = $null;
if ($Installer.Name -in 'Archive', 'Copy' -and $destination) {
    $stagingPath = "$env:TEMP\App_Updaters\Staging\$appName";
    Remove-Item -LiteralPath $stagingPath -Recurse -Force -ErrorAction SilentlyContinue;
    $stagingInstaller = @{ Name = $Installer.Name; Args = $Installer.Args.Clone() };
    $stagingInstaller.Args.Destination = $stagingPath;

    Write-Host "===================== Stage New Version =====================" -ForegroundColor Gray;
    $stagingArtifacts = ExecuteScript -Path "Installers" -Item $stagingInstaller -AdditionalArgs @{ Path = $downloadPath };
    if (!$stagingArtifacts.Success) {
        return New-Result 'Failed' "Could not unpack the new version. Nothing was cleaned.";
    }

    $relativeExe = $exePath ? [IO.Path]::GetRelativePath($destination, $exePath) : $null;
    if ($relativeExe -and !$relativeExe.StartsWith('..') -and !(Test-Path -LiteralPath (Join-Path $stagingPath $relativeExe))) {
        return New-Result 'Failed' "The new version has no '$relativeExe' where it is expected (wrong asset or archive layout). Nothing was cleaned.";
    }
}

$ownProcessIds = Get-OwnProcessIds;
$running = @(Get-AppProcesses -Folders $appFolders);
$script:runningNames = @($running | ForEach-Object { $_.Name } | Sort-Object -Unique);
if ($running | Where-Object { $ownProcessIds -contains $_.ProcessId }) {
    return New-Result 'Failed' "$appName is running this updater, update it from another shell. Nothing was cleaned.";
}
if ($running) {
    if (!(Confirm-Step "$appName is running ($($script:runningNames -join ', ')). Close it to update?")) {
        return New-Result 'Skipped' "Update skipped, $appName is running.";
    }

    # Only the top-level processes get restarted, not their children (e.g. Brave's renderers)
    $runningIds = @($running | ForEach-Object { $_.ProcessId });
    $script:toRestart = @($running |
            Where-Object { $_.ExecutablePath -and $runningIds -notcontains $_.ParentProcessId } |
            Group-Object ExecutablePath |
            ForEach-Object { @{ Path = $_.Group[0].ExecutablePath; Arguments = Get-ProcessArguments $_.Group[0] } });

    $running | ForEach-Object {
        Write-Host "[INFO] Closing $($_.Name) (PID $($_.ProcessId))" -ForegroundColor Yellow;
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue;
    }
    Start-Sleep -Seconds 2;
    $stillRunning = @($running | Where-Object { Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue });
    if ($stillRunning) {
        Restart-ClosedApps;
        return New-Result 'Failed' "Could not close $(($stillRunning | ForEach-Object { $_.Name }) -join ', ') (try running as admin). Nothing was cleaned.";
    }
}

#endregion

#region Backup, so a failed install can be rolled back

$backupRoot = "$env:TEMP\App_Updaters\Backup\$appName-$(Get-Date -Format 'yyyyMMdd-HHmmss')";
$backups = [System.Collections.Generic.List[hashtable]]::new();
foreach ($source in @($Cleaner.Args.Paths | Where-Object { $_ -and (Test-Path -LiteralPath $_) })) {
    $target = "$backupRoot\$($backups.Count)";
    New-Item -ItemType Directory -Force $target | Out-Null;
    $isFolder = Test-Path -LiteralPath $source -PathType Container;
    if ($isFolder) {
        robocopy $source $target /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null;
        $ok = $LASTEXITCODE -lt 8;
    }
    else {
        Copy-Item -LiteralPath $source -Destination $target -Force;
        $ok = $?;
    }
    if (!$ok) {
        Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction SilentlyContinue;
        Restart-ClosedApps;
        return New-Result 'Failed' "Could not back up '$source'. Nothing was cleaned.";
    }
    $backups.Add(@{ Source = $source; Backup = $target; IsFolder = $isFolder });
}

$preserved = @(@($Preserve) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | ForEach-Object {
        @{ Path = $_; Content = [IO.File]::ReadAllBytes($_) }
    });

function Restore-Backup {
    Write-Host "[WARN] Rolling back to the previous version..." -ForegroundColor Yellow;
    foreach ($backup in $backups) {
        if ($backup.IsFolder) {
            robocopy $backup.Backup $backup.Source /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null;
        }
        else {
            Copy-Item -LiteralPath (Join-Path $backup.Backup (Split-Path $backup.Source -Leaf)) -Destination $backup.Source -Force;
        }
    }
    Write-Host "[INFO] Previous version restored. Backup kept at $backupRoot" -ForegroundColor Yellow;
    Restart-ClosedApps;
}

#endregion

#region Clean + install

Write-Host "";
Write-Host "===================== Clean Old Version =====================" -ForegroundColor Gray;
$cleanerArtifacts = ExecuteScript -Path "Cleaners" -Item $Cleaner ;
if (!$cleanerArtifacts.Success) {
    Restore-Backup;
    return New-Result 'Failed' "Failed to clean old files for $appName, rolled back.";
}
Write-Host "===================== End Clean Old Version =====================" -ForegroundColor Gray;

if ($stagingPath) {
    New-Item -ItemType Directory -Force $destination | Out-Null;
    robocopy $stagingPath $destination /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null;
    $installed = $LASTEXITCODE -lt 8;
}
else {
    $installerArtifacts = ExecuteScript -Path "Installers" -Item $Installer -AdditionalArgs @{
        Path = $downloadPath
    }
    $installed = [bool]$installerArtifacts.Success;
}

if (!$installed -or ($exePath -and !(Test-Path -LiteralPath $exePath))) {
    Restore-Backup;
    return New-Result 'Failed' "Failed to install $appName $newVersion$($exePath ? " ($exePath missing after install)" : ''), rolled back.";
}

foreach ($file in $preserved) {
    [IO.File]::WriteAllBytes($file.Path, $file.Content);
    Write-Host "[INFO] Kept $(Split-Path $file.Path -Leaf)" -ForegroundColor DarkGray;
}

Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction SilentlyContinue;
if ($stagingPath) {
    Remove-Item -LiteralPath $stagingPath -Recurse -Force -ErrorAction SilentlyContinue;
}
Restart-ClosedApps;

#endregion

return New-Result 'Updated' "$appName updated $oldVersion -> $newVersion";
