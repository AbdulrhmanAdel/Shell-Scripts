[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$Options = @(
    @{
        Key     = "Add Movie To Notion";
        Handler = {
            $path = "$PSScriptRoot/Add-Movie/Add-Movie.ps1";
            & $path $Files;
        };
    }
)

. Create-Module.ps1 -Options $Options;
