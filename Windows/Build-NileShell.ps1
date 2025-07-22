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
                        Filter   = ".mp3|.m4a|.mp4|.mkv"
                        Title    = "Crop"
                        FilePath = "$ShellScripsPath\Media\Crop.ps1"
                    }
                    @{
                        Mode     = "single"
                        Target   = "file"
                        Filter   = ".mkv|.mp4"
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
                        Image    = "[\uE194,#f00]"
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
                Target   = "dir"
                Title    = "Youtube Downloader"
                Image    = "icon.youtube"
                FilePath = "Youtube\Downloader.ps1"
            },
            @{
                Target   = "file|dir|drive"
                Title    = "Safe Delete"
                Image    = "icon.delete"
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

function BuildCommand {
    param (
        $Item
    )
    if ($Item.FilePath) {
        $isAbsolute = [System.IO.Path]::IsPathRooted($Item.FilePath);
        $filePath = $isAbsolute ? $Item.FilePath : "$ShellScripsPath\$($Item.FilePath)";
        return "cmd='pwsh.exe' args='-File ""$($filePath)"" @sel(true, ' ')'";
    }

    return "cmd='pwsh.exe' args='-Command $($Item.Command) @sel(true, ' ')'";
}

function BuildItem {
    param (
        $Item,
        [Int16]$Depth = 1
    )
    $tab = (New-Object string[] $Depth) -join "  ";
    $image = $Item.Image ? " image=$($Item.Image) " : "";
    $command = BuildCommand -Item $Item;
    $mode = $Item.Mode ? " mode='$Item.Mode' " : "";
    $target = $Item.Target ? " type='$($Item.Target)' " : "";
    $filter = $Item.Filter ? " find='$($Item.Filter)' " : "";
    $global:FinalContent += "$($tab)item(title='$($Item.Title)'$($image)$($mode)$($target)$($filter)$($command))";
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

if (Prompt.ps1 -Message "Do you want to restart Explorer?") {
    $RestartExplorerPath = "$ShellScripsPath\Tools\Restart-Explorer.ps1";
    & $RestartExplorerPath;
}