[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Message,
    [string]$Title,
    $DefaultValue
)

if (($env:WAYLAND_DISPLAY -or $env:DISPLAY) -and (Get-Command kdialog -ErrorAction SilentlyContinue)) {
    & kdialog --title ($Title ? $Title : $Message) ($null -ne $DefaultValue ? '--yesnocancel' : '--yesno') $Message 2>$null;
    if ($LASTEXITCODE -eq 2) {
        return $DefaultValue;
    }
    return $LASTEXITCODE -eq 0;
}

$answer = Read-Host "$Message [y/n]";
return !$answer ? [bool]$DefaultValue : $answer -match '^y';
