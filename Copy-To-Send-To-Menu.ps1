if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $script = $MyInvocation.MyCommand.Path;
    $arguments = @(
        "-File", """$script"""
    );
    Start-Process pwsh.exe -Verb RunAs -ArgumentList $arguments;
    exit;
}

$sendToMenuFolder = "$($env:APPDATA)\Microsoft\Windows\SendTo";
$scriptPath = $PSScriptRoot;
#region Menu
$menu = @(
    @{
        Name      = "01- Remove Unused Tracks.lnk"
        Arguments = "-File ""$scriptPath\Media\Remove-Unused-Tracks.ps1"""
    },
    @{
        Name      = "02- Media - Display Chapters Info.lnk"
        Arguments = "-File ""$scriptPath\Media\Display-Chapter-Info.ps1"""
    },
    @{
        Name      = "02- Media - Remove Linked Segements.lnk"
        Arguments = "-File ""$scriptPath\Media\Remove-Segment-Link.ps1"""
    },
    @{
        Name      = "02- Media - Tracks Extractor.lnk"
        Arguments = "-File ""$scriptPath\Media\Extract-track.ps1"""
    },
    @{
        Name      = "02- Subtitle - Convert ASS To SRT.lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Convertors\Ass-To-Srt.ps1"""
    },
    @{
        Name      = "02- Subtitle - Editor (ASS).lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Editors\Ass-Editor.ps1"""
    },
    @{
        Name      = "02- Subtitle - Renamer.lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Subtitle Renamer\Subtitle-Renamer.ps1"""
    },
    @{
        Name      = "02- Subtitle - Shifter (Chapter Based).lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Subtitle-Shifter\Custom\Chapter-Based-Shifter.ps1"""
    },
    @{
        Name      = "02- Subtitle - Shifter.lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Subtitle-Shifter\Subtitle-Shifter.ps1"""
    },
    @{
        Name      = "500- Copy Paths To Clipboard.lnk"
        Arguments = "-File ""$scriptPath\Tools\Copy-Paths-To-Clipboard.ps1"""
    },
    @{
        Name      = "500- Copy To Different Drive With The Same Hierarchy.lnk"
        Arguments = "-File ""$scriptPath\Tools\Copy-To-Different-Drive-With-The-Same-Hierarchy.ps1"""
    }
)
     
#endregion
Remove-Item -LiteralPath $sendToMenuFolder -Force -Recurse;
if (!(Test-Path -LiteralPath $sendToMenuFolder)) {
    New-Item -Path $sendToMenuFolder -ItemType Directory -Force | Out-Null;
}

$menu | ForEach-Object {
    $sh = New-Object -ComObject WScript.Shell
    $path = "$sendToMenuFolder/$($_.Name)";
    $shortCut = $sh.CreateShortcut($path);
    $shortCut.TargetPath = "pwsh.exe";
    $shortCut.Arguments = "$($_.Arguments)";
    $shortCut.Save();
}