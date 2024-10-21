[CmdletBinding()]
param (
    [string]$IntialDirectory = [Environment]::GetFolderPath('MyDocuments'),
    [switch]$ExitIfNotSelected,
    [switch]$Required,
    [switch]$ShowHiddenFiles,
    $Filter
)

Add-Type -AssemblyName System.Windows.Forms;
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog;
$openFileDialog.InitialDirectory = $IntialDirectory;
$openFileDialog.ShowHiddenFiles = $ShowHiddenFiles
if ($Filter) {
    $openFileDialog.Filter = $Filter;
}

$openFileDialog.Dispose();
if ($openFileDialog.ShowDialog() -eq "OK") {
    return "$($openFileDialog.FileName)";
}

if ($ExitIfNotSelected) {
    [Environment]::Exit(0);
}

while ($Required -and $openFileDialog.ShowDialog() -ne 'OK') {}
return $null;
