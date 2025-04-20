[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$Options = @(
    @{
        Key        = "Downloader";
        Extensions = @("mkv", "mp4", "Directory");
        Handler    = {
            $path = "$PSScriptRoot/Downloader/Downloader.ps1";
            &  $path -Paths $Files;
        };
    }
    @{
        Key        = "Translate";
        Extensions = @("srt", "ass");
        Handler    = {
            $path = "$PSScriptRoot/Translate/Translate.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key        = "Shifter";
        Extensions = @("srt", "ass");
        Handler    = {
            $path = "$PSScriptRoot/Shifter/Shifter.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key        = "Shifter (Chapter Based)";
        Extensions = @("srt", "ass");
        Handler    = {
            $path = "$PSScriptRoot/Shifter/Custom/Chapter-Based-Shifter.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key        = "Editor";
        Extensions = @("srt", "ass");
        Handler    = {
            $path = "$PSScriptRoot/Editor/Editor.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key     = "Renamer";
        Handler = {
            $path = "$PSScriptRoot/Renamer/Renamer.ps1";
            & $path -Paths $Files;
        };
    }
    @{
        Key        = "Convertor";
        Extensions = @("srt", "ass");
        Handler    = {
            $path = "$PSScriptRoot/Convertor/Convertor.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key        = "Extract Then Translate";
        Extensions = @("mkv", "mp4");
        Handler    = {
            $path = "$PSScriptRoot/Extract-Translate.ps1";
            &  $path -Files $Files;
        };
    }
    @{
        Key     = "Choose Another Module";
        Handler = {
            Module-Picker.ps1 -Files $Files;
        };
    }
)


$FilesExtensions = @($Files | Foreach-Object {
        $ex = [System.IO.Path]::GetExtension($_);
        if (!$ex) {
            return "Directory"
        }
        return $ex -replace "^.", ""
    })

$options = $Options | Where-Object {
    $extensions = $_.Extensions;
    if (!$extensions) {
        return $true
    }

    return [bool]($FilesExtensions | Where-Object { $_ -in $extensions })
}


$option = Single-Options-Selector.ps1 -options $Options -MustSelectOne;
$option.Handler.Invoke();