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
            &  $path $Files;
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
    
)


$option = Single-Options-Selector.ps1 -options $Options -MustSelectOne;
$option.Handler.Invoke();


