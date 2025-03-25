[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$Options = @(
    @{
        Key     = "Remove Unused Tracks";
        Handler = {
            $path = "$PSScriptRoot/Remove-Unused-Tracks/Remove-Unused-Tracks.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key     = "Tracks Extractor";
        Handler = {
            $path = "$PSScriptRoot/Extract-Track.ps1";
            &  $path $Files;
        };
    }
    @{
        Key     = "Compress";
        Handler = {
            $path = "$PSScriptRoot/Compress/Compress.ps1";
            &  $path $Files;
        };
    }
    @{
        Key     = "Display Chapter Info";
        Handler = {
            $path = "$PSScriptRoot/Display-Chapter-Info.ps1";
            &  $path $Files;
        };
    }
    @{
        Key     = "Remove Segment Link";
        Handler = {
            $path = "$PSScriptRoot/Remove-Segment-Link.ps1";
            &  $path $Files;
        };
    }
    @{
        Key     = "Display Videos with Non-Arabic Subtitle";
        Handler = {
            $path = "$PSScriptRoot/Display-NonArabicSubtitled.ps1";
            &  $path $Files;
        };
    }
)


$option = Single-Options-Selector.ps1 -options $Options -MustSelectOne;
$option.Handler.Invoke();


