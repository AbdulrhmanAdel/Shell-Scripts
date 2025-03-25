[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$Options = @(
    @{
        Key     = "Translate";
        Handler = {
            $path = "$PSScriptRoot/Translate/Translate.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key     = "Shifter";
        Handler = {
            $path = "$PSScriptRoot/Shifter/Shifter.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key     = "Shifter (Chapter Based)";
        Handler = {
            $path = "$PSScriptRoot/Shifter/Custom/Chapter-Based-Shifter.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key     = "Downloader";
        Handler = {
            $path = "$PSScriptRoot/Downloader/Downloader.ps1";
            &  $path -Paths $Files;
        };
    }
    @{
        Key     = "Editor";
        Handler = {
            $path = "$PSScriptRoot/Editor/Editor.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key     = "Convertor";
        Handler = {
            $path = "$PSScriptRoot/Convertor/Convertor.ps1";
            &  $path -Files $Files;
        };
    }
)


$option = Single-Options-Selector.ps1 -options $Options -MustSelectOne;
$option.Handler.Invoke();


