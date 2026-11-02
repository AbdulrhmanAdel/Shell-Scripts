[CmdletBinding()]
param (
    [string]$Title = "Range Selector",
    [string]$Message = 'Select Range',
    [int]$TickFrequency = 10,
    [int]$Minimum = 0,
    [int]$Maximum = 100,
    [int]$DefaultValue = 0
)

return [int](& "$PSScriptRoot/Input.ps1" -Title $Title -Message "$Message ($Minimum - $Maximum)" -Type Number -Min $Minimum -Max $Maximum -NoDecimal -DefaultValue $DefaultValue);
