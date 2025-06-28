[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$Options = @(
    @{
        Key        = "Remove Unused Tracks";
        Extensions = @("mkv", "mp4", "zip", "rar");
        Handler    = {
            $path = "$PSScriptRoot/Remove-UnusedTracks/Main.ps1";
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
    @{
        Key     = "Fix Names";
        Handler = {
            $path = "$PSScriptRoot/FIx-SeriesNames.ps1";
            &  $path $Files;
        };
    }
)

. Create-Module.ps1 -Options $Options;


