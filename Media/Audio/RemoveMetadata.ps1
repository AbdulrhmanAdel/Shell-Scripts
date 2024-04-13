$targetPath = "";

$targetPathInfo = Get-Item -LiteralPath $targetPath;

function RemoveMetaData {
    param (
        $mediaPath
    )
    
}

if ($targetPathInfo -is [System.IO.DirectoryInfo]) {

}
else {
    RemoveMetaData -mediaPath $targetPath;
}