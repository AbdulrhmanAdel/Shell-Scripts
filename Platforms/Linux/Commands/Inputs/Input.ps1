[CmdletBinding()]
param (
    [string]$Title = "Please Enter Value",
    [string]$Message = "Please Enter Value",
    [ArgumentCompletions('Text', 'Number')]
    [string]$Type = "Text",
    [System.Nullable[int]]$DecimalPlaces,
    [switch]$MultiLine,
    [switch]$Required = $false,
    $DefaultValue,
    [System.Nullable[double]]$Min,
    [System.Nullable[double]]$Max,
    [switch]$NoDecimal
)

while ($true) {
    $text = (& kdialog --title $Title ($MultiLine ? '--textinputbox' : '--inputbox') $Message "$DefaultValue" 2>$null) -join "`n";
    $submitted = $LASTEXITCODE -eq 0;
    if (!$submitted -and $Required) {
        continue;
    }
    if (!$submitted -or !$text) {
        return $DefaultValue;
    }
    if ($Type -ne 'Number') {
        return $text;
    }

    $number = $text -as [double];
    $valid = $null -ne $number `
        -and ($null -eq $Min -or $number -ge $Min) `
        -and ($null -eq $Max -or $number -le $Max) `
        -and (!$NoDecimal -or $number % 1 -eq 0);
    if ($valid) {
        return $number;
    }
    & kdialog --title $Title --sorry "'$text' is not a valid number." 2>$null;
}
