[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Text
)

Set-Clipboard -Value $Text;
