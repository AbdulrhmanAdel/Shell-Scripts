Add-Type -AssemblyName System.Windows.Forms;

$foldername = New-Object System.Windows.Forms.FolderBrowserDialog
$foldername.Description = "Select a folder"
$foldername.rootfolder = "MyComputer"
$foldername.SelectedPath = $initialDirectory

if ($foldername.ShowDialog() -eq "OK") {
    $folder += $foldername.SelectedPath
}
return $folder