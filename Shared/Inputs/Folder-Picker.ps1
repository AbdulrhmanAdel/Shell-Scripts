[CmdletBinding()]
param (
    [string]$IntialDirectory = [Environment]::GetFolderPath('MyDocuments'),
    [switch]$ExitIfNotSelected,
    [switch]$Required,
    [switch]$ShowHiddenFiles
)

Add-Type -AssemblyName System.Windows.Forms;
$foldername = New-Object System.Windows.Forms.FolderBrowserDialog;
$foldername.InitialDirectory = $IntialDirectory;
$foldername.Dispose();
$foldername.ShowHiddenFiles = $ShowHiddenFiles;
if ($foldername.ShowDialog() -eq "OK") {
    return "$($foldername.SelectedPath)";
}

if ($ExitIfNotSelected) {
    [Environment]::Exit(0);
}

while ($Required -and $foldername.ShowDialog() -ne 'OK') {}
return $null;
