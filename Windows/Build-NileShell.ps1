$ShellScripsPath = Resolve-Path "$PSScriptRoot\..";
$global:FinalContent = @();
$Menus = @(
    @{
        Title      = "Scripts"
        Mode       = "multiple"
        Target     = "file|dir|drive|RecycleBin"
        Image      = "\uE231"
        Separators = @{
            Top    = $true
            Bottom = $true
        }
        Children   = @(
            @{
                Target   = "file|dir"
                Title    = "Module Picker"
                FilePath = "$ShellScripsPath\Shared\Module-Picker.ps1"
            }
            @{
                Title    = "Media"
                Target   = "file"
                Filter   = ".mp3|.m4a|.opus|.mp4|.mkv"
                Children = @(
                    @{
                        Target   = "file"
                        Filter   = ".mp3|.m4a|.opus|.mp4|.mkv"
                        Title    = "Crop"
                        FilePath = "$ShellScripsPath\Media\Crop.ps1"
                    }
                    @{

                        Target   = "file"
                        Filter   = ".mkv|.mp4"
                        Title    = "Display Chapters Info"
                        FilePath = "$ShellScripsPath\Media\Display-ChaptersInfo.ps1"
                    }
                )
            }
            @{
                Title    = "Icons"
                Target   = "dir"
                Children = @(
                    @{
                        Title          = "Set Or Refresh Icon"
                        FilePath       = "Icons\Set-Folder-Icon.ps1"
                        MultiExecution = $true
                    },
                    @{
                        Title          = "Remove Icon"
                        FilePath       = "Icons\Remove-Icon.ps1"
                        MultiExecution = $true
                    }
                )
            }
            @{
                Title    = "Icons"
                Filter   = ".png"
                Target   = "file"
                Children = @(
                    @{
                        Title          = "Convert To Icon"
                        FilePath       = "Icons\Utils\Convert-Png-To-Ico.ps1"
                        MultiExecution = $true
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
                        Image    = "\uE194"
                        FilePath = "Tools\Take-Ownership.ps1"
                    }
                    @{
                        Target  = "dir"
                        Title   = "Add To Path"
                        Command = "Add-ToPath.ps1"
                    }
                    @{
                        Target   = "file"
                        Title    = "Display Hash"
                        FilePath = "$ShellScripsPath\Tools\Hash\Display-Hash.ps1"
                    }
                    @{
                        Target   = "file|dir"
                        Title    = "Copy Paths"
                        FilePath = "$ShellScripsPath\Tools\Copy-PathsToClipboard.ps1"
                    }
                    @{
                        Target   = "file|dir"
                        Title    = "Copy Names"
                        FilePath = "$ShellScripsPath\Tools\Copy-FileNames.ps1"
                    }
                )
            }
            @{
                Title    = "Crawlers"
                Target   = "dir"
                Children = @(
                    @{
                        Target         = "dir"
                        Title          = "Anidl"
                        FilePath       = "Crawlers\Anidl.ps1"
                        MultiExecution = $true
                    }
                )
            }
            @{
                Target   = "dir"
                Title    = "Youtube Downloader"
                Image    = "[\uE248, #f00]"
                FilePath = "Youtube\Downloader.ps1"
            },
            @{
                Target   = "file|dir|drive|RecycleBin"
                Title    = "Safe Delete"
                Image    = "icon.delete"
                FilePath = "Tools\Safe-Delete.ps1"
            }
        )
    }
);

function BuildSeparator {
    param (
        $Item
    )
    $hasTop = ($Item.Separators)?.Top
    $hasBottom = ($Item.Separators)?.Bottom;
    if ($hasTop -and $hasBottom) {
        return " sep='both' ";
    }
    if ($hasTop) {
        return " sep=sep.top ";
    }
    if ($hasBottom) {
        return " sep=sep.bottom ";
    }
    return "";
} 

function BuildMenu {
    param (
        [object]$Menu,
        [Int16]$Depth = 1
    )

    $tab = (New-Object string[] $Depth) -join "  ";
    $Depth++;
    $target = $Menu.Target ? " type='$($Menu.Target)' " : "";
    $filter = $Menu.Filter ? " find='$($Menu.Filter)' " : "";
    $mode = $Menu.Mode ? " mode='$($Menu.Mode)' " : "";
    $image = $Menu.Image ? " image=$($Menu.Image) " : "";
    $separator = BuildSeparator -Item $Menu;
    $global:FinalContent += "$($tab)menu(where=sel.count>0 title='$($Menu.Title)'$($target)$($filter)$($mode)$($image)$($separator))";
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

    $isMultiExecution = !!$Item.MultiExecution;
    $selectionPlaceholder = $isMultiExecution ?'@sel.path.quote' : "@sel(true, ' ')";
    $invoke = $isMultiExecution ? " invoke='multiple' " : " ";
    if ($Item.FilePath) {
        $isAbsolute = [System.IO.Path]::IsPathRooted($Item.FilePath);
        $filePath = $isAbsolute ? $Item.FilePath : "$ShellScripsPath\$($Item.FilePath)";
        return "cmd='pwsh.exe'$($invoke)args='-File ""$($filePath)"" $selectionPlaceholder'";
    }

    return "cmd='pwsh.exe' $invoke args='-Command $($Item.Command) $selectionPlaceholder'";
}

function BuildItem {
    param (
        $Item,
        [Int16]$Depth = 1
    )
    $tab = (New-Object string[] $Depth) -join "  ";
    $image = $Item.Image ? " image=$($Item.Image) " : " image ";
    $command = BuildCommand -Item $Item;
    $mode = $Item.Mode ? " mode='$Item.Mode' " : "";
    $target = $Item.Target ? " type='$($Item.Target)' " : "";
    $filter = $Item.Filter ? " find='$($Item.Filter)' " : "";
    $separator = BuildSeparator -Item $Item;
    $global:FinalContent += "$($tab)item(title='$($Item.Title)'$($image)$($mode)$($target)$($filter)$($separator)$($command))";
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