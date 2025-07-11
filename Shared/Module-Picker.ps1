[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments)]
    [string[]]
    $Files
)

$Module = Single-Options-Selector.ps1 -Options @(
    @{
        Key   = "Media";
        Value = @{ Title = "Media"; Path = "$PSScriptRoot/../Media/Module.ps1" };
    }
    @{
        Key   = "Subtitles";
        Value = @{ Title = "Subtitles"; Path = "$PSScriptRoot/../Subtitles/Module.ps1" };
    }
    @{
        Key   = "Tools";
        Value = @{ Title = "Tools"; Path = "$PSScriptRoot/../Tools/Module.ps1" };
    }
) -Required;

if (!$Module) {
    Exit;
}

$ModulePath = Resolve-Path -Path $Module.Path -ErrorAction Ignore;
Write-Host "Selected Module: $($Module.Title)" -ForegroundColor Green;
& $ModulePath.Path -Files $Files;
timeout.exe 20