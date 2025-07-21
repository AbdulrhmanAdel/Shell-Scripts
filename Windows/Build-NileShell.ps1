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
                Title    = "Module Picker"
                FilePath = "$ShellScripsPath\Shared\Module-Picker.ps1"
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
    $global:FinalContent += "$($tab)menu(where=sel.count>0 type='$($Menu.Target)' mode=""$($Menu.Mode)"" title='$($Menu.Title)' image=$($Menu.Image))";
    $global:FinalContent += "$tab{"
    foreach ($child in $Menu.Children) {
        if ($child.Type -eq "Menu") {
            BuildMenu -Menu $child -Depth $Depth;
            continue;
        }

        BuildItem -Item $child -Depth $Depth;
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

$SavePath = [Environment]::GetEnvironmentVariable("Nile-Soft", "User") + "\imports\my-config.nss"
Set-Content $SavePath -Value $global:FinalContent;