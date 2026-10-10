function Invoke-Copy {
    param (
        [string[]]$Files,
        [string]$Destination,
        [switch]$Move,
        [switch]$Verify
    )

    $shell = New-Object -ComObject "Shell.Application";
    $folder = $shell.NameSpace($Destination);
    foreach ($file in $Files) {
        if ($Move) {
            $folder.MoveHere($file, 88);
        }
        else {
            $folder.CopyHere($file, 88);
        }

        if ($Verify) {
            & "$PSScriptRoot\..\..\Check-FolderSync.ps1" -Source $file -Target "$Destination\$(Split-Path -Leaf $file)" -CheckHashes $true;
        }
    }

    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null;
}

Export-ModuleMember -Function Invoke-Copy;
