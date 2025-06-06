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
            $path = "$PSScriptRoot/Copy-Paths-To-Clipboard.ps1";
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
            & $path $Files;
        };
    }
    @{
        Key     = "Move";
        Handler = {
            $path = "$PSScriptRoot/Copy.ps1";
            & $path -Files $Files -Move;
        };
    }
)

. Create-Module.ps1 -Options $Options;