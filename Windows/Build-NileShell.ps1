$ShellScripsPath = Resolve-Path "$PSScriptRoot\..";
$global:FinalContent = @();
$Menus = @(
    @{
        Title    = "Scripts"
        Mode     = "multiple"
        Target   = "file|dir|drive|namespace|back"
        Image    = "\uE1F4"
        Children = @(
            @{
                Target   = "file|dir"
                Title    = "Module Picker"
                FilePath = "$ShellScripsPath\Shared\Module-Picker.ps1"
            }
            @{
                Title    = "Media"
                Mode     = "multiple"
                Target   = "file|dir"
                Image    = "\uE1F4"
                Children = @(
                    @{
                        Mode     = "single"
                        Target   = "file"
                        Filter   = ExtensionFilter -Extensions @(".mp3", ".m4a", ".mp4", ".mkv")
                        Title    = "Crop"
                        FilePath = "$ShellScripsPath\Media\Crop.ps1"
                    }
                    @{
                        Mode     = "single"
                        Target   = "file"
                        Filter   = ExtensionFilter -Extensions @(".mkv", ".mp4")
                        Title    = "Display Chapters Info"
                        FilePath = "$ShellScripsPath\Media\Display-Chapter-Info.ps1"
                    }
                )
            }
            @{
                Title    = "Icons"
                Mode     = "single"
                Target   = "file|dir"
                Image    = "\uE1F4"
                Children = @(
                    @{
                        Target   = "dir"
                        Title    = "Set Or Refresh Icon"
                        FilePath = "Icons\Set-Folder-Icon.ps1"
                    },
                    @{
                        Target   = "dir"
                        Title    = "Remove Icon"
                        FilePath = "Icons\Remove-Icon.ps1"
                    },
                    @{
                        Target   = "file"
                        Filter   = ".png"
                        Title    = "Convert To Icon"
                        FilePath = "Icons\Utils\Convert-Png-To-Ico.ps1"
                    }
                )
            }
            @{
                Title    = "Tools"
                Mode     = "multiple"
                Target   = "file|dir"
                Children = @(
                    @{
                        Target   = "file|dir"
                        Title    = "TakeOwn"
                        FilePath = "$ShellScripsPath\Tools\Takeown.ps1"
                    }
                    @{
                        Target  = "file|dir"
                        Title   = "Add To Path"
                        Command = "Add-ToPath.ps1"
                    }
                    @{
                        Target   = "file"
                        Title    = "Display Hash"
                        FilePath = "$ShellScripsPath\Tools\Hash\Display-Hash.ps1"
                    }
                )
            }
            @{
                Title    = "Crawlers"
                Mode     = "single"
                Target   = "dir"
                Children = @(
                    @{
                        Target   = "dir"
                        Title    = "Anidl"
                        FilePath = "Crawlers\Anidl.ps1"
                    }
                )
            }
            @{
                Title    = "Youtube Downloader"
                FilePath = "Youtube\Downloader.ps1"
            },
            @{
                Target   = "file|dir|drive"
                Title    = "Safe Delete"
                FilePath = "Tools\Safe-Delete.ps1"
            }
        )
    }
);

function BuildMenu {
    param (
        [object]$Menu,
        [Int16]$Depth = 1
    )

    $tab = (New-Object string[] $Depth) -join "  ";
    $Depth++;
    $global:FinalContent += "$($tab)menu(where=sel.count>0 type='$($Menu.Target)' mode=""$($Menu.Mode)"" title='$($Menu.Title)' image=$($Menu.Image ? $Menu.Image : "inherit"))";
    $global:FinalContent += "$tab{"
    foreach ($child in $Menu.Children) {
        if (-not $child.Children) {
            BuildItem -Item $child -Depth $Depth;
            continue;
        }

        BuildMenu -Menu $child -Depth $Depth;
    }
    $global:FinalContent += "$tab}"
}

function BuildItem {
    param (
        $Item,
        [Int16]$Depth = 1
    )
    $tab = (New-Object string[] $Depth) -join "  ";
    $global:FinalContent += "$($tab)item(title='$($Item.Title)' image=inherit cmd='pwsh.exe' args='-File ""$($Item.FilePath)"" @sel(true, "" "")')";
}


foreach ($menu in $Menus) {
    BuildMenu -Menu $menu;
}

$nileSoftPath = [Environment]::GetEnvironmentVariable("Nile-Soft", "User");
if (-not $nileSoftPath) {
    $nileSoftPath = Folder-Picker.ps1 -InitialDirectory "D:\";
    [Environment]::SetEnvironmentVariable("Nile-Soft", $nileSoftPath, "User");
}

$SavePath = "$nileSoftPath\imports\my-config.nss"
Set-Content $SavePath -Value $global:FinalContent;