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
# Staging and backups. Linux has no %TEMP%, and its /tmp is in RAM while a backup holds the whole app folder
# (with a portable app's personal files), so they go on the disk there.
$tempRoot = $IsLinux ? ($env:XDG_CACHE_HOME ?? "$HOME/.cache") : $env:TEMP;

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
    return & "$PSScriptRoot/$Path/$($Item.Name)" @finalArgs;
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

    $command = Get-Command "$PSScriptRoot/$Path/$($Item.Name).ps1" -ErrorAction SilentlyContinue;
    $command ??= Get-Command "$PSScriptRoot/$Path/$($Item.Name)" -ErrorAction SilentlyContinue;
    if (!$command) {
        return @("<script $Path/$($Item.Name) not found>");
    }

    $supplied = @($AdditionalArgs.Keys) + @($Item.Args.Keys);
    return @($command.Parameters.Values | Where-Object {
            $_.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }
        } | Where-Object { $supplied -notcontains $_.Name } | ForEach-Object { $_.Name });
}

# Every process with the properties of Win32_Process: Name, ProcessId, ParentProcessId, ExecutablePath, CommandLine
function Get-ProcessTable {
    if (!$IsLinux) {
        return @(Get-CimInstance Win32_Process);
    }

    return @([IO.Directory]::GetDirectories('/proc') | Where-Object { (Split-Path $_ -Leaf) -match '^\d+$' } | ForEach-Object {
            try {
                # pid (name) state ppid ...: the name can hold spaces and brackets, so split after the last ")"
                $stat = [IO.File]::ReadAllText("$_/stat");
                $nameEnd = $stat.LastIndexOf(')');
                $parentId = [int]($stat.Substring($nameEnd + 2) -split ' ')[1];
                $path = $null;
                # Unreadable for other users' processes
                try { $path = [IO.File]::ResolveLinkTarget("$_/exe", $false).FullName -replace ' \(deleted\)$', '' } catch {}

                # An AppImage runs from a temporary mount, so its real path is only in the environment. Apps it starts
                # (e.g. a browser opening a link) inherit that environment, hence the check that it runs from the mount.
                if ($path) {
                    try {
                        $environment = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes("$_/environ")) -split "`0";
                        $appImage = $environment -match '^APPIMAGE=' | Select-Object -First 1;
                        $appDir = $environment -match '^APPDIR=' | Select-Object -First 1;
                        if ($appImage -and $appDir -and $path.StartsWith(($appDir -replace '^APPDIR=', '').TrimEnd('/') + '/')) {
                            $path = $appImage -replace '^APPIMAGE=', '';
                        }
                    }
                    catch {}
                }

                $arguments = @([Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes("$_/cmdline")).TrimEnd("`0") -split "`0" | Select-Object -Skip 1);
                [pscustomobject]@{
                    Name            = $stat.Substring($stat.IndexOf('(') + 1, $nameEnd - $stat.IndexOf('(') - 1)
                    ProcessId       = [int](Split-Path $_ -Leaf)
                    ParentProcessId = $parentId
                    ExecutablePath  = $path
                    # Quoted like on Windows, so Get-ProcessArguments can read it
                    CommandLine     = (@("""$path""") + @($arguments | ForEach-Object { $_ -match '\s' ? """$_""" : $_ })) -join ' '
                }
            }
            catch {
                # The process ended while it was being read
            }
        });
}

# Processes running from one of the folders
function Get-AppProcesses {
    param ([string[]]$Folders)

    $Folders = @($Folders | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | ForEach-Object { (Resolve-Path -LiteralPath $_).Path.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar });
    if (!$Folders) {
        return @();
    }

    # Elevated processes hide their path from a normal shell, so also match by the exe names found in the folders
    $exeNames = @($Folders | ForEach-Object { Get-ChildItem -LiteralPath $_ -Filter *.exe -Recurse -Depth 2 -File -ErrorAction SilentlyContinue } | ForEach-Object { $_.Name }) | Sort-Object -Unique;
    return @(Get-ProcessTable | Where-Object {
            $path = $_.ExecutablePath;
            ($path -and ($Folders | Where-Object { $path.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) })) -or
            (!$path -and $exeNames -contains $_.Name)
        });
}

# This updater and the shells that started it (e.g. updating PowerShell from PowerShell)
function Get-OwnProcessIds {
    $processes = @(Get-ProcessTable);
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
        if ($IsLinux) {
            # In its own session, so closing this terminal does not close the app too. Without its own output,
            # or whoever reads the updater's output would wait until the app is closed.
            $startArgs.ArgumentList = """$($app.Path)"" $($app.Arguments)".Trim();
            $startArgs.FilePath = 'setsid';
            $startArgs.RedirectStandardOutput = '/dev/null';
            $startArgs.RedirectStandardError = '/dev/null';
            $startArgs.RedirectStandardInput = '/dev/null';
        }
        Start-Process @startArgs;
        $script:restarted += Split-Path $app.Path -Leaf;
        Write-Host "[INFO] Restarted $(Split-Path $app.Path -Leaf)" -ForegroundColor DarkGray;
    }
}

# Copies a folder's contents. -Mirror also removes what the source does not have.
function Copy-FolderContent {
    param (
        [string]$Source,
        [string]$Target,
        [switch]$Mirror
    )

    if ($IsLinux) {
        if ($Mirror) {
            & find $Target -mindepth 1 -delete;
        }
        # -a keeps the executable bits and symlinks
        & cp -a -- "$Source/." $Target;
        return $LASTEXITCODE -eq 0;
    }

    robocopy $Source $Target ($Mirror ? '/MIR' : '/E') /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null;
    return $LASTEXITCODE -lt 8;
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

# Archive/Copy/Inno/AdvancedInstaller installs go to a staging folder first, so a wrong asset or archive layout is caught before cleaning
$stagingPath = $null;
if ($Installer.Name -in 'Archive', 'Copy', 'Inno', 'AdvancedInstaller' -and $destination) {
    $stagingPath = "$tempRoot/App_Updaters/Staging/$appName";
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

$backupRoot = "$tempRoot/App_Updaters/Backup/$appName-$(Get-Date -Format 'yyyyMMdd-HHmmss')";
$backups = [System.Collections.Generic.List[hashtable]]::new();
foreach ($source in @($Cleaner.Args.Paths | Where-Object { $_ -and (Test-Path -LiteralPath $_) })) {
    $target = "$backupRoot/$($backups.Count)";
    New-Item -ItemType Directory -Force $target | Out-Null;
    $isFolder = Test-Path -LiteralPath $source -PathType Container;
    if ($isFolder) {
        $ok = Copy-FolderContent -Source $source -Target $target;
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
            New-Item -ItemType Directory -Force $backup.Source | Out-Null;
            Copy-FolderContent -Source $backup.Backup -Target $backup.Source -Mirror | Out-Null;
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
# No cleaner means nothing to clean, e.g. a setup.exe that upgrades in place
if ($Cleaner.Name -and !$cleanerArtifacts.Success) {
    Restore-Backup;
    return New-Result 'Failed' "Failed to clean old files for $appName, rolled back.";
}
Write-Host "===================== End Clean Old Version =====================" -ForegroundColor Gray;

if ($stagingPath) {
    New-Item -ItemType Directory -Force $destination | Out-Null;
    $installed = Copy-FolderContent -Source $stagingPath -Target $destination;
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
    # The new version may not ship the file's folder at all (e.g. Node's etc\npmrc)
    New-Item -ItemType Directory -Force (Split-Path $file.Path) | Out-Null;
    [IO.File]::WriteAllBytes($file.Path, $file.Content);
    Write-Host "[INFO] Kept $(Split-Path $file.Path -Leaf)" -ForegroundColor DarkGray;
}

# Files without a version (every Linux binary) read it back from here on the next run
if ($CurrentVersion.Args.VersionFile -and $newVersion) {
    Set-Content -LiteralPath $CurrentVersion.Args.VersionFile -Value $newVersion;
}

Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction SilentlyContinue;
if ($stagingPath) {
    Remove-Item -LiteralPath $stagingPath -Recurse -Force -ErrorAction SilentlyContinue;
}
Restart-ClosedApps;

#endregion

return New-Result 'Updated' "$appName updated $oldVersion -> $newVersion";
