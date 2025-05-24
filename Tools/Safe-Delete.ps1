# -c	Clean free space.
# -f	Force arguments containing only letters to be treated as a file/directory rather than a disk.
# Not required if the argument contains other characters (path separators or file extensions for example).
# -p	Specifies number of overwrite passes (default is 1).
# -q	Quiet mode.
# -r	Remove Read-Only attribute.
# -s	Recurse subdirectories.
# -z	Zero free space (good for virtual disk optimization).
# -nobanner	Do not display the startup banner and copyright message.

[CmdletBinding()]
param (
    [switch]$Prompt,
    [switch]$PromptPasses,
    [switch]$RunAsAdmin,
    [Parameter(ValueFromRemainingArguments = $true)]
    $Files
)

if ($RunAsAdmin -or (Prompt.ps1 -Message "Run As Admin?")) {
    Run-AsAdmin.ps1 -Arguments (@(
        "-Prompt", $Prompt,
        "-PromptPasses", $PromptPasses
    ) + $Files);
}
Write-Host $Files
Write-Host "These Files Are going to be deleted:" -ForegroundColor Green;
$Files | ForEach-Object { Write-Host $_  -ForegroundColor Red; }
$passes = @();
if ($PromptPasses) { 
    $noOfPasses = & Range-Selector.ps1 -title "Passes" -message "Select Number of passes" -minimum 1 -maximum 5  -defaultValue 1  -tickFrequency 1;
    $passes += @("-p", $noOfPasses);
}

if ($Prompt) {
    $continue = & Prompt.ps1 -message "Are you sure you want to remove these files?";
    if (!$continue) {
        Write-Host "ABORTED" -ForegroundColor Red
        timeout 5;
        EXIT;
    }
}

function Delete {
    param (
        $procesArgs
    )
    
    $procesArgs = @("-nobanner") + $passes + $procesArgs;
    Start-Process sdelete -ArgumentList $procesArgs -Wait -NoNewWindow;
}

$Files | ForEach-Object {
    Write-Host $isDrive $_;

    $isDrive = $_ -match '^(?<Drive>[a-z]:)"$';
    if ($isDrive) {
        $drive = $Matches.Drive;
        $deleteType = & Single-Options-Selector.ps1 -Options @("Format Disk", "Clean Free Space");
        if (!$deleteType) {
            return;
        }

        if ($deleteType -eq "Format Disk") {
            Delete -procesArgs @("-z", $drive);
            Get-ChildItem -LiteralPath "$drive/" | ForEach-Object {
                Delete -procesArgs @("-r", "-s", """$($_)""");
            };
        }
        
        Delete -procesArgs @("-c", $drive);
        return;
    }

    if ($_ -eq "C:\`$Recycle.Bin") {
        Delete -procesArgs @("-r", "-s", """$($_)\*""");
        return;
    }
    
    Delete -procesArgs @("-r", "-s", """$($_)""");
}    


timeout 5;