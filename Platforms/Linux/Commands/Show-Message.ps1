[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Message,
    [string]$Title = 'Message'
)

& kdialog --title $Title --sorry $Message 2>$null;
