[CmdletBinding()]
param (
    $Options,
    [string]$Title,
    [switch]$Multi,
    [switch]
    [Alias("MustSelectOne")]
    $Required,
    $SelectedOptions,
    [int]$Columns = 0
)

$Options = @($Options);
$SelectedOptions ??= @();
$arguments = @('--title', $Title, '--separate-output', '--checklist', ($Title ? $Title : 'Select Options'));
for ($index = 0; $index -lt $Options.Count; $index++) {
    $option = $Options[$index];
    $arguments += @("$index", "$($option.Key ?? $option)", ($SelectedOptions -contains $option ? 'on' : 'off'));
}

$selected = @(& kdialog @arguments 2>$null);
while ($Required -and !$selected) {
    Write-Host "You Must Select An Option" -ForegroundColor Red;
    $selected = @(& kdialog @arguments 2>$null);
}

return $selected | ForEach-Object {
    $option = $Options[[int]$_];
    $option.Key ? ($option.Value ?? $option) : $option;
};
