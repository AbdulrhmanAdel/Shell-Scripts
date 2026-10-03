<#
.SYNOPSIS
    Open the folder of a shim's (or shortcut's) target with the target file selected.
.DESCRIPTION
    A shim is an .exe with a .shim file next to it holding the target path (see New-Shim.ps1).
    Accepts the .shim file, the shim .exe (its sibling .shim is read) or a .lnk shortcut, and opens
    Explorer on the target's folder with the target highlighted.
    Problems are reported in a message box, since it runs with a hidden window from the context menu.
.PARAMETER Paths
    Paths of the .shim / .exe / .lnk files.
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
)

function Resolve-Target([string]$Path) {
    $extension = [IO.Path]::GetExtension($Path).ToLower();
    if ($extension -eq '.lnk') {
        return (New-Object -ComObject WScript.Shell).CreateShortcut($Path).TargetPath;
    }

    $shimPath = [IO.Path]::ChangeExtension($Path, '.shim');
    if (Test-Path -LiteralPath $shimPath -PathType Leaf) {
        return (Get-Content -LiteralPath $shimPath -Raw).Trim();
    }

    return $null;
}

if (!$Paths) {
    $Paths = & File-Picker.ps1 -Title 'Select Shim' -Filter 'Shims|*.shim;*.exe;*.lnk' -Multiple -ExitIfNotSelected;
}

$errors = @();
foreach ($path in $Paths) {
    $target = Resolve-Target $path;
    if (!$target) {
        $errors += "No shim or shortcut target found for:`n$path";
        continue;
    }

    if (Test-Path -LiteralPath $target) {
        Start-Process explorer.exe -ArgumentList "/select,`"$target`"";
        continue;
    }

    # The target itself is gone, fall back to the closest folder that still exists.
    $folder = Split-Path -Parent $target;
    while ($folder -and !(Test-Path -LiteralPath $folder -PathType Container)) {
        $folder = Split-Path -Parent $folder;
    }

    $errors += "Target does not exist:`n$target";
    if ($folder) {
        Start-Process explorer.exe -ArgumentList "`"$folder`"";
    }
}

if ($errors) {
    Add-Type -AssemblyName System.Windows.Forms;
    [System.Windows.Forms.MessageBox]::Show(
        ($errors -join "`n`n"),
        'Open Target Location',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null;
}
