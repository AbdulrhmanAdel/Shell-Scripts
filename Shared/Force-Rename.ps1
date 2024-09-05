function ForceRename {
    param (
        $path,
        $newName
    )
    
    $RenameError = $null;
    Rename-Item -LiteralPath $path -NewName $newName -Force -ErrorVariable RenameError | Out-Null;
    if (!$RenameError.Count) {
        return
    }

    Read-Host $RenameError -ForegroundColor Red;
    ForceRename -path $path -newName $newName
}


. Parse-Args.ps1 $args;
if (!$path -or !$newName) {
    $message = "YOU MUST PROVIDE PATH AND NEW NAME, You PASSED path: $path, newName: $newName";
    Write-Host $message -ForegroundColor Red;
    throw $message;
    return;
}

ForceRename -path $path -newName $newName;