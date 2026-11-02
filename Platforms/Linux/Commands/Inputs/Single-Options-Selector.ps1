[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [System.Object[]]
    $Options,
    [switch]
    [Alias("MustSelectOne")]
    $Required = $false,
    [string]$Title = "Select an Option",
    [string]$Message,
    [System.Object]$DefaultValue,
    [int]$Columns = 0
)

$arguments = @('--title', $Title, '--menu', ($Message ? $Message : $Title));
for ($index = 0; $index -lt $Options.Count; $index++) {
    $option = $Options[$index];
    $arguments += @("$index", "$($option.Key ?? $option)");
    if ($null -ne $DefaultValue -and ($option.Value ?? $option) -eq $DefaultValue) {
        $arguments += @('--default', "$index");
    }
}

$selected = & kdialog @arguments 2>$null;
while ($Required -and $null -eq $DefaultValue -and $null -eq $selected) {
    Write-Host "You Must Select An Option" -ForegroundColor Red;
    $selected = & kdialog @arguments 2>$null;
}

if ($null -eq $selected) {
    return $DefaultValue;
}

$option = $Options[[int]$selected];
return $option.Value ?? $option;
