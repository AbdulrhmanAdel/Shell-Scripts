[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$Options = @(
    @{
        Key     = "Take Ownership";
        Handler = {
            $path = "$PSScriptRoot/Take-Ownership.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key     = "Copy-Paths-To-Clipboard";
        Handler = {
            $path = "$PSScriptRoot/Copy-PathsToClipboard.ps1";
            &  $path -Paths $Files;
        };
    }
    @{
        Key     = "Safe Delete";
        Handler = {
            $path = "$PSScriptRoot/Safe-Delete.ps1";
            & $path -Files $Files;
        };
    }
    @{
        Key     = "Validate Shortcuts";
        Handler = {
            $path = "$PSScriptRoot/Validate-Shortcut.ps1";
            & $path $Files;
        };
    }
    @{
        Key     = "Copy";
        Handler = {
            $path = "$PSScriptRoot/Copy.ps1";
            & $path -Files $Files;
        };
    }
    @{
        Key     = "Move";
        Handler = {
            $path = "$PSScriptRoot/Copy.ps1";
            & $path -Files $Files -Move;
        };
    }
    @{
        Key     = "Create SymbolicLink";
        Handler = {
            $Target = Folder-Picker.ps1 -InitialDirectory ([System.IO.Path]::GetDirectoryName($Files[0])) -Required;
            $Files | ForEach-Object {
                & Create-SymbolicLink.ps1 -Source $_ -Target $Target
            }
        };
    }
    @{
        Key     = "Create PathShortcut";
        Handler = {
            & "$PSScriptRoot\Create-PathShortcut.ps1" -Files $Files
        };
    }
    @{
        Key     = "Check Folder Sync";
        Handler = {
            $Source = $Files.Length -gt 0 ? $Files[0] : (Folder-Picker.ps1 -Title "Please Pick Source Folder." -ShowOnTop -Required);
            $Target = $Files.Length -gt 1  ? $Files[1] : (Folder-Picker.ps1 -Title "Please Pick Target Folder." -ShowOnTop -Required);
            $ReverseCheck = Prompt.ps1 -Message "Check Reverse?";
            & "$PSScriptRoot\Check-FolderSync.ps1" -Source $Source -Target $Target -ReverseCheck $ReverseCheck;
        };
    }
)

. Create-Module.ps1 -Options $Options;