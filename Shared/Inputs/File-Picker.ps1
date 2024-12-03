[CmdletBinding()]
param (
    [string]$InitialDirectory = [Environment]::GetFolderPath('MyDocuments'),
    [switch]$ExitIfNotSelected,
    [switch]$Required,
    [switch]$ShowHiddenFiles,
    [switch]$ShowOnTop,
    $Filter,
    [int]$Retry
)

Add-Type -AssemblyName System.Windows.Forms;
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog;
$openFileDialog.InitialDirectory = $InitialDirectory;
$openFileDialog.ShowHiddenFiles = $ShowHiddenFiles
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
    return "$($openFileDialog.FileName)";
}

if ($ExitIfNotSelected) {
    [Environment]::Exit(0);
}

$WithRetry = $Retry -gt 0;
while (($Required -or ($WithRetry -and $Retry -gt 0)) -and $openFileDialog.ShowDialog($dialogOption) -ne 'OK') {
    $Retry--;
}
return $null;
