# -c	Clean free space.
# -f	Force arguments containing only letters to be treated as a file/directory rather than a disk.
# Not required if the argument contains other characters (path separators or file extensions for example).
# -p	Specifies number of overwrite passes (default is 1).
# -q	Quiet mode.
# -r	Remove Read-Only attribute.
# -s	Recurse subdirectories.
# -z	Zero free space (good for virtual disk optimization).
# -nobanner	Do not display the startup banner and copyright message.

Write-Host $args
$continue = & Prompt.ps1 "Are you sure you want to remove these files?";
if (!$continue) {
    Write-Host "ABORTED" -ForegroundColor Red
    timeout 15;
    EXIT;
}


function Delete {
    param (
        $procesArgs
    )
    
    $procesArgs = @("-nobanner") + $procesArgs;
    Start-Process sdelete -ArgumentList $procesArgs -Wait -NoNewWindow;
}

$files = $args;
$files | ForEach-Object {
    $isDrive = $_ -match '^(?<Drive>[a-z]:)"$';
    if ($isDrive) {
        $drive = $Matches.Drive;
        Delete -procesArgs @("-c", $drive)
        # $deleteType = & Options-Selector.ps1 @("Format Disk", "Clean Free Space");
        # if ($deleteType -eq "Clean Free Space") {
        # }
        # elseif ($deleteType -eq "Format Disk") {
        #     Delete -procesArgs @("-f", "$drive/")
        # }
        return;
    }

    $procesArgs = @("-r");
    $isDirectory = (Get-Item -LiteralPath $_) -is [System.IO.DirectoryInfo];
    if ($isDirectory) {
        $procesArgs += "-s";
    } 

    $procesArgs += """$($_)""";
    Delete -procesArgs $procesArgs;
}    


timeout 15;