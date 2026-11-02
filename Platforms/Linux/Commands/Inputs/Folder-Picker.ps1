[CmdletBinding()]
param (
    [string]$InitialDirectory = [Environment]::GetFolderPath('MyDocuments'),
    [switch]$ExitIfNotSelected = $false,
    [string]$Title = "Select Directory",
    [switch]$Required = $false,
    [switch]$ShowHiddenFiles = $false,
    [switch]$ShowOnTop = $false,
    [int]$Retry = 0
)

$selected = & kdialog --title $Title --getexistingdirectory $InitialDirectory 2>$null;
if (!$selected -and $ExitIfNotSelected) {
    [Environment]::Exit(0);
}

while (!$selected -and ($Required -or $Retry-- -gt 0)) {
    $selected = & kdialog --title $Title --getexistingdirectory $InitialDirectory 2>$null;
}

return $selected ? "$selected" : $null;
