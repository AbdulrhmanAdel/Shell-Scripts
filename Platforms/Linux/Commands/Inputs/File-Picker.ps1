[CmdletBinding()]
param (
    [string]$InitialDirectory = [Environment]::GetFolderPath('MyDocuments'),
    [switch]$ExitIfNotSelected,
    [switch]$Required,
    [switch]$ShowHiddenFiles,
    [switch]$ShowOnTop,
    [Switch]$Multiple,
    [string]$Title = "Select File",
    $Filter,
    [int]$Retry
)

$arguments = @('--title', $Title, '--getopenfilename', $InitialDirectory);
if ($Filter) {
    $parts = $Filter -split '\|';
    $arguments += @(for ($index = 0; $index + 1 -lt $parts.Count; $index += 2) {
            "$($parts[$index]) ($(($parts[$index + 1] -replace '\*\.\*', '*') -replace ';', ' '))"
        }) -join '|';
}
if ($Multiple) {
    $arguments += @('--multiple', '--separate-output');
}

$selected = @(& kdialog @arguments 2>$null);
if (!$selected -and $ExitIfNotSelected) {
    [Environment]::Exit(0);
}

while (!$selected -and ($Required -or $Retry-- -gt 0)) {
    $selected = @(& kdialog @arguments 2>$null);
}

if (!$selected) {
    return $null;
}

return $Multiple ? $selected : $selected[0];
