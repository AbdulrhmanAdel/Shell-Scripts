[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]
    $FolderPath
)

$folderName = [System.IO.Path]::GetFileName($FolderPath);
$space = ' ';

$newFolderName = "$folderName$space"
if ($folderName -match $space) {
    $newFolderName = "$folderName" -replace $space, ''
}
Rename-Item -LiteralPath $FolderPath -NewName $newFolderName;