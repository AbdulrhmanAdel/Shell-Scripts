[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]
    $FolderPath
)

$folderName = [System.IO.Path]::GetFileName($FolderPath);
$newFolderName = "$folderName "
Rename-Item -LiteralPath $FolderPath -NewName $newFolderName;