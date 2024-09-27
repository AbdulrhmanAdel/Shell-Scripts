[CmdletBinding()]
param (
    [string]$IntialDirectory = [Environment]::GetFolderPath('MyDocuments'),
    [switch]$ExitIfNotSelected
)

Add-Type -AssemblyName System.Windows.Forms;
$foldername = New-Object System.Windows.Forms.FolderBrowserDialog
$foldername.InitialDirectory = $IntialDirectory;
$foldername.Dispose();
if ($foldername.ShowDialog() -eq "OK") {
    return "$($foldername.SelectedPath)";
}

if ($ExitIfNotSelected) {
    [Environment]::Exit(0);
}

return $null;
