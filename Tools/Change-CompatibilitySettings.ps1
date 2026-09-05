<#
.SYNOPSIS
    View and toggle the Windows compatibility settings (AppCompatFlags layers) of an executable.
.DESCRIPTION
    Reads the compatibility layers currently applied to the given executable (or the target of a
    shortcut) and shows every supported option in a multi-option selector form, pre-checking the
    ones already applied. Whatever is checked on submit becomes the new set of layers, unchecking
    everything clears the settings entirely.
.PARAMETER ExePath
    Path of the executable (or .lnk shortcut pointing to one). Passed as remaining arguments so
    unquoted paths containing spaces still work when invoked from the context menu.
.PARAMETER Wait
    Seconds to keep the console open after applying the changes.
#>
# PositionalBinding is off so an unquoted path is not partially bound to the other parameters,
# every loose argument lands in $ExePath instead.
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string]$ExePath,
    [int]$Wait = 5
)

#region Flags

# Group: options inside the same group are mutually exclusive (they are radio buttons/dropdowns in
# the native Compatibility tab), options without a group are independent checkboxes.
$compatibilityFlags = @(
    @{ Name = 'Compatibility mode: Windows 95'; Tokens = @('WIN95'); Group = 'CompatibilityMode' }
    @{ Name = 'Compatibility mode: Windows 98 / Windows Me'; Tokens = @('WIN98'); Group = 'CompatibilityMode' }
    @{ Name = 'Compatibility mode: Windows XP (Service Pack 2)'; Tokens = @('WINXPSP2'); Group = 'CompatibilityMode' }
    @{ Name = 'Compatibility mode: Windows XP (Service Pack 3)'; Tokens = @('WINXPSP3'); Group = 'CompatibilityMode' }
    @{ Name = 'Compatibility mode: Windows Vista'; Tokens = @('VISTARTM'); Group = 'CompatibilityMode' }
    @{ Name = 'Compatibility mode: Windows Vista (Service Pack 1)'; Tokens = @('VISTASP1'); Group = 'CompatibilityMode' }
    @{ Name = 'Compatibility mode: Windows Vista (Service Pack 2)'; Tokens = @('VISTASP2'); Group = 'CompatibilityMode' }
    @{ Name = 'Compatibility mode: Windows 7'; Tokens = @('WIN7RTM'); Group = 'CompatibilityMode' }
    @{ Name = 'Compatibility mode: Windows 8'; Tokens = @('WIN8RTM'); Group = 'CompatibilityMode' }

    @{ Name = 'Reduced color mode: 8-bit (256) color'; Tokens = @('256COLOR'); Group = 'ColorMode' }
    @{ Name = 'Reduced color mode: 16-bit (65536) color'; Tokens = @('16BITCOLOR'); Group = 'ColorMode' }
    @{ Name = 'Run in 640 x 480 screen resolution'; Tokens = @('640X480') }
    @{ Name = 'Disable fullscreen optimizations'; Tokens = @('DISABLEDXMAXIMIZEDWINDOWEDMODE') }
    @{ Name = 'Run this program as an administrator'; Tokens = @('RUNASADMIN') }
    @{ Name = 'Run this program without elevation (as invoker)'; Tokens = @('RUNASINVOKER') }
    @{ Name = 'Register this program for restart'; Tokens = @('REGISTERAPPRESTART') }
    @{ Name = 'Use legacy display ICC color management'; Tokens = @('TRANSFORMLEGACYCOLORMANAGED') }
    @{ Name = 'Disable visual themes (legacy)'; Tokens = @('DISABLETHEMES') }
    @{ Name = 'Disable desktop composition (legacy)'; Tokens = @('DISABLEDWM') }

    @{ Name = 'High DPI scaling override: Application'; Tokens = @('HIGHDPIAWARE'); Group = 'DpiOverride' }
    @{ Name = 'High DPI scaling override: System'; Tokens = @('DPIUNAWARE'); Group = 'DpiOverride' }
    @{ Name = 'High DPI scaling override: System (Enhanced)'; Tokens = @('GDIDPISCALING', 'DPIUNAWARE'); Group = 'DpiOverride' }

    @{ Name = 'Program DPI: use the DPI set when I signed in to Windows'; Tokens = @('PERPROCESSSYSTEMDPIFORCEON'); Group = 'ProgramDpi' }
    @{ Name = 'Program DPI: use the DPI set when I open this program'; Tokens = @('PERPROCESSSYSTEMDPIFORCEOFF'); Group = 'ProgramDpi' }
);

#endregion

#region Path Resolution

if (!$ExePath) {
    $ExePath = & File-Picker.ps1 -Filter 'Applications|*.exe;*.lnk|All Files|*.*' -ExitIfNotSelected;
}

if ($ExePath.EndsWith('.lnk')) {
    $shell = New-Object -ComObject WScript.Shell;
    $shortcut = $shell.CreateShortcut($ExePath);
    $ExePath = $shortcut.TargetPath;
}

if (!$ExePath -or !(Test-Path -LiteralPath $ExePath -PathType Leaf)) {
    Write-Host "Could not resolve an existing file from the given path: '$ExePath'" -ForegroundColor Red;
    timeout.exe $Wait;
    Exit 1;
}

$ExePath = (Resolve-Path -LiteralPath $ExePath).ProviderPath;
Write-Host "Changing compatibility settings for $ExePath" -ForegroundColor Green;

#endregion

#region Current Settings

$regPath = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers";
# The value name is the full path, which may contain wildcard characters, so read it through the
# registry key itself instead of Get-ItemProperty -Name (that one treats the name as a wildcard).
$regKey = Get-Item -LiteralPath $regPath -ErrorAction SilentlyContinue;
$regValue = $regKey ? $regKey.GetValue($ExePath) : $null;
Write-Host "Current settings: $($regValue ?? 'None')" -ForegroundColor Cyan;

$currentTokens = @(($regValue ?? '') -split '\s+' | Where-Object { $_ -and $_ -ne '~' });
# Multi token flags first, so "GDIDPISCALING DPIUNAWARE" wins over a bare "DPIUNAWARE".
$appliedFlags = @();
$matchedTokens = @();
$compatibilityFlags | Sort-Object { - $_.Tokens.Count } | ForEach-Object {
    $flag = $_;
    $missing = @($flag.Tokens | Where-Object { $currentTokens -notcontains $_ -or $matchedTokens -contains $_ });
    if ($missing.Count -gt 0) {
        return;
    }

    $appliedFlags += $flag;
    $matchedTokens += $flag.Tokens;
}

# Anything the script does not know about is preserved as is instead of being silently dropped.
$unknownTokens = @($currentTokens | Where-Object { $matchedTokens -notcontains $_ });
if ($unknownTokens.Count -gt 0) {
    Write-Host "Keeping unrecognized layers: $($unknownTokens -join ' ')" -ForegroundColor Yellow;
}

#endregion

#region Selection

$options = $compatibilityFlags | ForEach-Object { [PSCustomObject]@{ Key = $_.Name; Value = $_ } };
$selectedOptions = @($options | Where-Object { $appliedFlags -contains $_.Value });
$chosenFlags = @(
    & Multi-Options-Selector.ps1 `
        -Title "Compatibility Settings - $(Split-Path -Leaf $ExePath)" `
        -Options $options `
        -SelectedOptions $selectedOptions
);

# Groups are mutually exclusive, so keep the option that was just checked over the previous one.
$chosenFlags = @(
    $chosenFlags | Group-Object { $_.Group } | ForEach-Object {
        if (!$_.Name -or $_.Count -eq 1) {
            return $_.Group;
        }

        $added = @($_.Group | Where-Object { $appliedFlags -notcontains $_ });
        $winner = $added.Count -gt 0 ? $added[-1] : $_.Group[0];
        $dropped = @($_.Group | Where-Object { $_ -ne $winner } | ForEach-Object { "'$($_.Name)'" }) -join ', ';
        Write-Host "'$($winner.Name)' replaces $dropped" -ForegroundColor Yellow;
        return $winner;
    }
);

$before = @($appliedFlags | ForEach-Object { $_.Name } | Sort-Object) -join "|";
$after = @($chosenFlags | ForEach-Object { $_.Name } | Sort-Object) -join "|";
if ($before -eq $after) {
    Write-Host "Nothing changed" -ForegroundColor Green;
    timeout.exe $Wait;
    Exit;
}

$newTokens = @(@($chosenFlags | ForEach-Object { $_.Tokens }) + $unknownTokens);
if ($newTokens.Count -eq 0 -and $regValue) {
    Add-Type -AssemblyName System.Windows.Forms;
    $confirmation = [System.Windows.Forms.MessageBox]::Show(
        "Remove all compatibility settings from`n$ExePath ?",
        'Change Compatibility Settings',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    );

    if ($confirmation -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Host "Cancelled, settings left untouched" -ForegroundColor Yellow;
        timeout.exe $Wait;
        Exit;
    }
}

#endregion

#region Apply

if ($newTokens.Count -eq 0) {
    Remove-ItemProperty -LiteralPath $regPath -Name $ExePath;
    Write-Host "All compatibility settings removed" -ForegroundColor Green;
    timeout.exe $Wait;
    Exit;
}

if (!$regKey) {
    New-Item -Path $regPath -Force | Out-Null;
}

# The leading '~' marks the entry as a user applied set of layers.
$newValue = "~ $($newTokens -join ' ')";
Set-ItemProperty -LiteralPath $regPath -Name $ExePath -Value $newValue;
Write-Host "New settings: $newValue" -ForegroundColor Green;
$chosenFlags | ForEach-Object { Write-Host "  + $($_.Name)" -ForegroundColor Green; };
$appliedFlags | Where-Object { $chosenFlags -notcontains $_ } | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor DarkGray;
}

timeout.exe $Wait;

#endregion
