[CmdletBinding()]
param (
    [Parameter()]
    [string[]]
    $Files
)

$Module = Single-Options-Selector.ps1 -Options @(
    @{
        Key   = "Media";
        Value = "$PSScriptRoot/../Media/Module.ps1";
    }
    @{
        Key   = "Subtitles";
        Value = "$PSScriptRoot/../Subtitles/Module.ps1";
    }
    @{
        Key   = "Audio";
        Value = "$PSScriptRoot/../Tools/Module.ps1";
    }
) -Required;

if (!$Module) {
    Exit;
}

# Write-Host "Selected Module: $Module" -ForegroundColor Green;
$ModulePath = Resolve-Path -Path $Module -ErrorAction Ignore;
Write-Host "Selected Module: $Module" -ForegroundColor Green;
& $ModulePath.Path -Files $Files;
timeout.exe 20