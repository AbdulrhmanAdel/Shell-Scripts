[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$Options = @(
    @{
        Key        = "Auto Select Tracks";
        Extensions = @("mkv", "mp4", "zip", "rar");
        Handler    = {
            $path = "$PSScriptRoot/Auto-Select-PreferredTracks/Main.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key     = "Tracks Extractor";
        Handler = {
            $path = "$PSScriptRoot/Extract-Track/Extract-Track.ps1";
            &  $path $Files;
        };
    }
    @{
        Key     = "Tracks Extractor (Subtitles Only)";
        Handler = {
            $path = "$PSScriptRoot/Extract-Track/Extract-Track.ps1";
            & $path -FirstSubtitle $Files;
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
            $path = "$PSScriptRoot/Display-ChaptersInfo/Display-ChaptersInfo.ps1";
            &  $path $Files;
        };
    }
    @{
        Key     = "Remove Segment Link";
        Handler = {
            $path = "$PSScriptRoot/Remove-Segment-Link/Remove-Segment-Link.ps1";
            &  $path $Files;
        };
    }
    @{
        Key     = "Display Videos with Non-Arabic Subtitle";
        Handler = {
            $path = "$PSScriptRoot/Display-NonArabicSubtitled/Display-NonArabicSubtitled.ps1";
            &  $path $Files;
        };
    }
    @{
        Key     = "Fix Names";
        Handler = {
            $path = "$PSScriptRoot/Fix-SeriesNames/Fix-SeriesNames.ps1";
            &  $path $Files;
        };
    }
)

. Create-Module.ps1 -Options $Options;


