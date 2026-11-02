[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Message,
    [string]$Title = 'Message'
)

Add-Type -AssemblyName System.Windows.Forms;
[System.Windows.Forms.MessageBox]::Show(
    $Message,
    $Title,
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Warning
) | Out-Null;
