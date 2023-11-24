
$folderName = $args[0];
$gitFolderName = "$folderName\.git";

Write-Output $folderName;
Write-Output $gitFolderName;
Write-Output "STARTING IN 5S"
Start-Sleep -Seconds 5

$takeOwn = "TakeOwn";
&$takeOwn /f "$gitFolderName" /r /d y
&$takeOwn /f "$folderName"
Write-Output "EXITING IN 5S"
Start-Sleep -Seconds 5