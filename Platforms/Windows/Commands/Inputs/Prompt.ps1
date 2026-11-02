<#
.SYNOPSIS
    Asks a yes/no question and returns the answer as a boolean.
.PARAMETER DefaultValue
    Returned when the dialog is closed instead of answered.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Message,
    [string]$Title,
    $DefaultValue
)

. "$PSScriptRoot\Form-Style.ps1";

$layout = New-InputForm -Title ($Title ?? $Message) -Message $Message;
$form = $layout.Form;

Add-InputFormButton -Layout $layout -Text 'Yes' -DialogResult OK -Accept | Out-Null;
Add-InputFormButton -Layout $layout -Text 'No' -DialogResult No -Cancel | Out-Null;

Set-InputFormSize -Layout $layout -Bounds (Get-InputFormBounds) -MinWidth 340 -MinHeight 150;
$result = $form.ShowDialog();
$form.Dispose();
if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
    return $DefaultValue ?? $false;
}

return $result -eq [System.Windows.Forms.DialogResult]::OK;
