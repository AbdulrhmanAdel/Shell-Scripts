Add-Type -AssemblyName System.Windows.Forms;

$intialDirectory = $args[0];
if (!$intialDirectory) {
    $intialDirectory = [Environment]::GetFolderPath('MyDocuments');
}

$foldername = New-Object System.Windows.Forms.FolderBrowserDialog
$foldername.InitialDirectory = $intialDirectory;
if ($foldername.ShowDialog() -eq "OK") {
    return "$($foldername.SelectedPath)";
}

return $null;
