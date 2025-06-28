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

Add-Type -AssemblyName System.Windows.Forms;
$foldername = New-Object System.Windows.Forms.FolderBrowserDialog;
$foldername.InitialDirectory = $InitialDirectory;
$foldername.Description = $Title;
$foldername.UseDescriptionForTitle = $true;
$foldername.Dispose();
$foldername.ShowHiddenFiles = $ShowHiddenFiles;
$dialogOption = New-Object System.Windows.Forms.Form;
if ($ShowOnTop) {
    $dialogOption.TopMost = $true;
    $dialogOption.TopLevel = $true;
}

if ($foldername.ShowDialog($dialogOption) -eq "OK") {
    return "$($foldername.SelectedPath)";
}

if ($ExitIfNotSelected) {
    [Environment]::Exit(0);
}

$WithRetry = $Retry -gt 0;
while (($Required -or ($WithRetry -and $Retry -gt 0)) -and $foldername.ShowDialog($dialogOption) -ne 'OK') {
    $Retry--;
}
return $null;
