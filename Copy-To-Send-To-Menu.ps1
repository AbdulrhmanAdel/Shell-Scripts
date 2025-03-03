& Run-AsAdmin.ps1;
# Install-Package SharpShell;

Write-Host "Copying To Send To Menu" -ForegroundColor Green;
$sendToMenuFolder = "$($env:APPDATA)\Microsoft\Windows\SendTo";
$scriptPath = $PSScriptRoot;
#region Menu
$menu = @(
    @{
        Name      = "01- Remove Unused Tracks.lnk"
        Arguments = "-File ""$scriptPath\Media\Remove-Unused-Tracks\Remove-Unused-Tracks.ps1"""
    },
    @{
        Name      = "9999- Copy.lnk"
        Arguments = "-File ""$scriptPath\Tools\Copy-ToDrive.ps1"" -CustomDestiniation -Files"
    },
    # @{
    #     Name      = "02- Media - Display Chapters Info.lnk"
    #     Arguments = "-File ""$scriptPath\Media\Display-Chapter-Info.ps1"""
    # },
    # @{
    #     Name      = "02- Media - Remove Linked Segements.lnk"
    #     Arguments = "-File ""$scriptPath\Media\Remove-Segment-Link.ps1"""
    # },
    @{
        Name      = "02- Media - Tracks Extractor.lnk"
        Arguments = "-File ""$scriptPath\Media\Extract-track.ps1"""
    },
    @{
        Name      = "02- Subtitle - Translate.lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Translate\Translate.ps1"""
    },
    @{
        Name      = "02- Subtitle - Convertor.lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Convertors\Subtitle-Convertor.ps1"""
    },
    @{
        Name      = "02- Subtitle - Editor.lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Editors\Subtitle-Editor.ps1"""
    },
    @{
        
        Name      = "02- Subtitle - Renamer.lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Renamer\Renamer.ps1"""
    },
    @{
        Name      = "02- Subtitle - Shifter (Chapter Based).lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Shifter\Custom\Chapter-Based-Shifter.ps1"""
    },
    @{
        Name      = "02- Subtitle - Shifter.lnk"
        Arguments = "-File ""$scriptPath\Media\Subtitles\Shifter\Shifter.ps1"""
    },
    @{
        Name       = "03- Subtitle - Downloader.lnk"
        Arguments  = "-File ""$scriptPath\Media\Subtitles\Downloader\Downloader.ps1"""
        SuffixArgs = @();
    },
    @{
        Name      = "450- Display - Not Arabic Subtitled Media.lnk"
        Arguments = "-File ""$scriptPath\Media\Display-NonArabicSubtitled.ps1"""
    },
    @{
        Name      = "500- Copy Paths To Clipboard.lnk"
        Arguments = "-File ""$scriptPath\Tools\Copy-Paths-To-Clipboard.ps1"""
    },
    # @{
    #     Name      = "500- Copy To Different Drive With The Same Hierarchy.lnk"
    #     Arguments = "-File ""$scriptPath\Tools\Copy-To-Different-Drive-With-The-Same-Hierarchy.ps1"""
    # },
    @{
        Name      = "601- Compress.lnk"
        Arguments = "-File ""$scriptPath\Media\Compress\Compress.ps1"""
    },
    @{
        Name       = "999- Safe Delete.lnk"
        Arguments  = "-File ""$scriptPath\Tools\Safe-Delete.ps1"""
        SuffixArgs = @();
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
    $shortCut.Arguments = "-WindowStyle Maximized $($_.Arguments)";
    $shortCut.Save();
}

Write-Host "Done" -ForegroundColor Green;
timeout.exe 5;