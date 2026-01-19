[CmdletBinding()]
param (
    [string]$InitialDirectory = [Environment]::GetFolderPath('MyDocuments'),
    [switch]$ExitIfNotSelected,
    [switch]$Required,
    [switch]$ShowHiddenFiles,
    [switch]$ShowOnTop,
    [Switch]$Multiple,
    $Filter,
    [int]$Retry
)

Add-Type -AssemblyName System.Windows.Forms;
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog;
$openFileDialog.InitialDirectory = $InitialDirectory;
$openFileDialog.Title = $Title;
$openFileDialog.ShowHiddenFiles = $ShowHiddenFiles
$openFileDialog.Multiselect = $Multiple;
if ($Filter) {
    $openFileDialog.Filter = $Filter;
}

$openFileDialog.Dispose();
$dialogOption = New-Object System.Windows.Forms.Form;
if ($ShowOnTop) {
    $dialogOption.TopMost = $true;
    $dialogOption.TopLevel = $true;
}

if ($openFileDialog.ShowDialog($dialogOption) -eq "OK") {
    return $Multiple ? $openFileDialog.FileNames : "$($openFileDialog.FileName)";
}

if ($ExitIfNotSelected) {
    [Environment]::Exit(0);
}

$WithRetry = $Retry -gt 0;
while (($Required -or ($WithRetry -and $Retry -gt 0)) -and $openFileDialog.ShowDialog($dialogOption) -ne 'OK') {
    $Retry--;
}
return $null;
