<#
.SYNOPSIS
    Re-point a shortcut (.lnk) to a new target and fix its working directory and icon along with it.
.DESCRIPTION
    Opens a picker to choose the new target. The picker type is detected from the old target: a
    folder picker if it pointed to a folder, otherwise a file picker filtered to the old extension.
    The working directory and icon location are remapped from the old location to the new one, so
    the icon does not keep pointing to the old (moved) path. A missing icon falls back to the target.
.PARAMETER ShortcutPath
    Path of the .lnk shortcut. Passed as remaining arguments so unquoted paths containing spaces
    still work when invoked from the context menu. A file picker is shown when omitted.
.PARAMETER Wait
    Seconds to keep the console open after applying the changes.
#>
# PositionalBinding is off so an unquoted path is not partially bound to the other parameters,
# every loose argument lands in $ShortcutPath instead.
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string]$ShortcutPath,
    [int]$Wait = 5
)

#region Helpers

function Get-ExistingParent([string]$Path) {
    while ($Path -and !(Test-Path -LiteralPath $Path -PathType Container)) {
        $Path = Split-Path -Parent $Path;
    }

    return $Path;
}

# Swaps the $OldRoot prefix of $Path for $NewRoot, returns $null when $Path is not under $OldRoot.
function Convert-PathRoot([string]$Path, [string]$OldRoot, [string]$NewRoot) {
    if (!$Path -or !$OldRoot) {
        return $null;
    }

    $Path = $Path.TrimEnd('\');
    if ($Path -ieq $OldRoot) {
        return $NewRoot;
    }

    if ($Path.StartsWith("$OldRoot\", [StringComparison]::OrdinalIgnoreCase)) {
        return Join-Path $NewRoot $Path.Substring($OldRoot.Length + 1);
    }

    return $null;
}

#endregion

#region Path Resolution

if (!$ShortcutPath) {
    $ShortcutPath = & File-Picker.ps1 -Title 'Select Shortcut' -Filter 'Shortcuts|*.lnk' -ExitIfNotSelected;
}

if (!(Test-Path -LiteralPath $ShortcutPath -PathType Leaf) -or !$ShortcutPath.EndsWith('.lnk')) {
    Write-Host "Not an existing shortcut: '$ShortcutPath'" -ForegroundColor Red;
    timeout.exe $Wait;
    Exit 1;
}

$ShortcutPath = (Resolve-Path -LiteralPath $ShortcutPath).ProviderPath;
$shell = New-Object -ComObject WScript.Shell;
$shortcut = $shell.CreateShortcut($ShortcutPath);
$oldTarget = $shortcut.TargetPath;
Write-Host "Shortcut: $ShortcutPath" -ForegroundColor Green;
Write-Host "Current target: $($oldTarget ? $oldTarget : 'None')" -ForegroundColor Cyan;

#endregion

#region Target Selection

# The old target is usually gone (that's why it is being changed), so fall back to the extension.
$oldExtension = [IO.Path]::GetExtension($oldTarget);
$isFolder = (Test-Path -LiteralPath $oldTarget -PathType Container) -or ($oldTarget -and !$oldExtension);
$initialDirectory = (Get-ExistingParent $oldTarget) ?? [Environment]::GetFolderPath('Desktop');

if ($isFolder) {
    $newTarget = & Folder-Picker.ps1 -Title "New target folder for $(Split-Path -Leaf $ShortcutPath)" -InitialDirectory $initialDirectory -ExitIfNotSelected;
}
else {
    $filter = $oldExtension ? "$($oldExtension.TrimStart('.').ToUpper()) Files|*$oldExtension|All Files|*.*" : 'All Files|*.*';
    $newTarget = & File-Picker.ps1 -Title "New target for $(Split-Path -Leaf $ShortcutPath)" -InitialDirectory $initialDirectory -Filter $filter -ExitIfNotSelected;
}

if (!$newTarget) {
    Exit;
}

$newTarget = $newTarget.TrimEnd('\');

#endregion

#region Apply

# Remap from the folder that held the old target, so a working directory or icon that lived next to
# (or inside) it follows the move too.
$oldRoot = $isFolder ? $oldTarget.TrimEnd('\') : (Split-Path -Parent $oldTarget);
$newRoot = $isFolder ? $newTarget : (Split-Path -Parent $newTarget);

$oldWorkingDirectory = $shortcut.WorkingDirectory;
$newWorkingDirectory = Convert-PathRoot $oldWorkingDirectory $oldRoot $newRoot;
if (!$newWorkingDirectory -and !$isFolder -and !(Test-Path -LiteralPath $oldWorkingDirectory)) {
    $newWorkingDirectory = $newRoot;
}

$oldIcon = $shortcut.IconLocation;
$iconIndex = $oldIcon -replace '^.*,', '';
$iconPath = [Environment]::ExpandEnvironmentVariables(($oldIcon -replace ',-?\d+$', ''));
$newIconPath = Convert-PathRoot $iconPath $oldRoot $newRoot;
if ($newIconPath -and !(Test-Path -LiteralPath $newIconPath)) {
    $newIconPath = $null;
}

# Default/blank icons (",0" or the generic shell32 one) are replaced by the target's own icon.
$isDefaultIcon = !$iconPath -or $iconPath -imatch '\\shell32\.dll$' -or !(Test-Path -LiteralPath $iconPath);
if (!$newIconPath -and $isDefaultIcon) {
    $newIconPath = $isFolder ? '' : $newTarget;
    $iconIndex = 0;
}

$shortcut.TargetPath = $newTarget;
if ($newWorkingDirectory) {
    $shortcut.WorkingDirectory = $newWorkingDirectory;
}

if ($null -ne $newIconPath) {
    $shortcut.IconLocation = "$newIconPath,$iconIndex";
}

try {
    $shortcut.Save();
}
catch {
    Write-Host "Failed to save the shortcut (it may need admin rights): $($_.Exception.Message)" -ForegroundColor Red;
    timeout.exe $Wait;
    Exit 1;
}

# Rebuild the icon cache so Explorer stops showing the stale icon.
ie4uinit.exe -show;

Write-Host "Target: $oldTarget -> $newTarget" -ForegroundColor Green;
if ($newWorkingDirectory) {
    Write-Host "Working directory: $oldWorkingDirectory -> $newWorkingDirectory" -ForegroundColor Green;
}

if ($null -ne $newIconPath) {
    Write-Host "Icon: $oldIcon -> $($shortcut.IconLocation)" -ForegroundColor Green;
}

timeout.exe $Wait;

#endregion
