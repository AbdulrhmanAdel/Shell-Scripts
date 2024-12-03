# Max Entries = 16
& Run-AsAdmin.ps1;

Write-Host "Starting" -ForegroundColor Green;
$Recycle = "RecycleBin";
$baseScriptsPath = $PSScriptRoot;
function BuildScript {
    param (
        [string]$scriptPath,
        [string]$PathParamName,
        [string[]]$additionalArgs,
        [string]$target,
        [string]$powershellArgs
    )

    $finalArgs = "";
    if ($additionalArgs) {
        $finalArgs = ($additionalArgs | ForEach-Object { return "$_" }) -join " "
    }

    $target ??= "%1";
    return "pwsh.exe $($powershellArgs) -file ""$baseScriptsPath\$scriptPath"" $PathParamName ""$target"" $finalArgs";
}

function Handle {
    param (
        $base,
        $element,
        $extension
    )
    
    foreach ($path in $element.Path) {
        $base = "$base\$($path.Key)"
        CreateMenu -base "$base" -title $path.Title;
        $base = "$base\shell";
    }

    $key = $element.Key;
    $target = $extension -eq $Recycle ? "$($env:SystemDrive)\`$Recycle.bin" : "%1";
    $command = BuildScript -scriptPath $element.ScriptPath `
        -PathParamName $element.PathParamName `
        -additionalArgs $element.AdditionalArgs `
        -target $target `
        -powershellArgs $element.PowershellArgs;

    reg add "$base\$key" /d $element.Title /t REG_SZ /f | Out-Null;
    if ($element.Icon) {
        reg add "$base\$key" /v "Icon" /d $element.Icon /t REG_SZ /f | Out-Null;
    }
    reg add "$base\$key\Command" /d $command /t REG_SZ /f | Out-Null;
}

function CreateMenu {
    param (
        [string]$base,
        [string]$title,
        [string]$icon
    )
    
    reg add $base  /v "MUIVerb" /d $title /t REG_SZ /f | Out-Null;
    reg add $base  /v "SubCommands" /t REG_SZ /f | Out-Null;
    reg add "$base\shell" /v "Icon" /t REG_SZ /f | Out-Null;
}


#region Vars 
# $baseScriptsPath = @(
#     @{
#         Title = "Scripts"
#         Key   = "0 Scripts"
#     }
# )

$mediaPath = @(
    @{
        Title = "Media" 
        Key   = "0 Media" 
    }
);

$iconsPath = @(
    @{
        Title = "Icons" 
        Key   = "091 Icons" 
    }
)

$attributesPath = @(
    @{
        Title = "Attributes"
        Key   = "092 Attributes"
    }
)

$infoPath = @(
    @{
        Title = "Info"
        Key   = "092 Info"
    }
)
# $windowsPath = @(
#     @{
#         Title = "Windows" 
#         Key   = "5 Windows" 
#     }
# );
$toolsPath = @(
    @{
        Title = "Tools" 
        Key   = "10 Tools" 
    }
);

$youtubePath = @(
    @{
        Title = "Youtube Downloader" 
        Key   = "10 Youtube Downloader" 
    }
);

$scripts = @(
    @{
        Extensions = @(".mp3", ".m4a", ".mp4", ".mkv")
        Title      = "Crop"
        Key        = "999 Crop"
        ScriptPath = "Media\Crop.ps1"
        Path       = $mediaPath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @(".mkv", ".mp4")
        Title      = "Display Chapters Info"
        Key        = "000 Display Chapters Info"
        ScriptPath = "Media\Display-Chapter-Info.ps1"
        Path       = $mediaPath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @("*", "Directory")
        Title      = "TakeOwn"
        Key        = "TakeOwn"
        ScriptPath = "Tools\Takeown.ps1"
        Path       = $toolsPath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @("Directory")
        Title      = "Add To Environment Varaibles"
        Key        = "Add To Environment Varaibles"
        ScriptPath = "Tools\Add-To-Environment-Varaibles.ps1"
        Path       = $toolsPath
        Icon       = "pwsh.exe"
    },
    
    @{
        Extensions = @("*")
        Title      = "Get Hash"
        Key        = "999-Get Hash"
        ScriptPath = "Tools\Display-Hash.ps1"
        Path       = $toolsPath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @("Directory")
        Title      = "Download Youtube Video"
        Key        = "90 Download Youtube Video"
        ScriptPath = "Youtube\Download-Video.ps1"
        Path       = @()
        Icon       = "pwsh.exe"
    },
    @{
        Extensions     = @("Drive", "*", "Directory", $Recycle)
        Title          = "Safe Delete"
        Key            = "99 Safe Delete"
        ScriptPath     = "Tools\Safe-Delete.ps1"
        Path           = @()
        Icon           = "pwsh.exe"
        AdditionalArgs = @("--prompt")
    },
    @{
        Extensions = @("Directory")
        Title      = "Set Or Refresh Icon"
        Key        = "0 Set Or Refresh Icon"
        ScriptPath = "Icons\Set-Folder-Icon.ps1"
        Path       = $iconsPath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @("Directory")
        Title      = "Remove Icon"
        Key        = "8 Remove Icon"
        ScriptPath = "Icons\Remove-Icon.ps1"
        Path       = $iconsPath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @(".png")
        Title      = "Convert To Icon"
        Key        = "0 Convert To Icon"
        ScriptPath = "Icons\Utils\Convert-Png-To-Ico.ps1"
        Path       = $iconsPath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @("Directory")
        Title      = "Open Folder Icon Info.ini"
        Key        = "9 Open Folder Icon Info.ini"
        ScriptPath = "Icons\Open-FolderIconInfo.ps1"
        Path       = $iconsPath
        Icon       = "pwsh.exe"
    }#,
    # @{
    #     Extensions = @("*", "Directory")
    #     Title      = "Display Attributes"
    #     Key        = "Display Attributes"
    #     ScriptPath = "Attributes\Display-Attributes.ps1"
    #     Path       = $attributesPath
    #     Icon       = "pwsh.exe"
    # },
    # @{
    #     Extensions = @("*", "Directory")
    #     Title      = "Change Attributes"
    #     Key        = "Change Attributes"
    #     ScriptPath = "Attributes\Change-Attributes.ps1"
    #     Path       = $attributesPath
    #     Icon       = "pwsh.exe"
    # }#,
    # @{
    #     Extensions = @("Directory")
    #     Title      = "Display Folder Content"
    #     Key        = "Display Folder Content"
    #     ScriptPath = "Tools\Display-Folder-Content.ps1"
    #     Path       = $infoPath
    #     Icon       = "pwsh.exe"
    # },
    @{
        Extensions = @("*")
        Title      = "Pin To Start"
        Key        = "Pin To Start"
        ScriptPath = "Tools\Pin-File-To-Start.ps1"
        Path       = $toolsPath
        Icon       = "pwsh.exe"
    } #,
    # @{
    #     Extensions = @("*", "Directory")
    #     Title      = "Create Symblink"
    #     Key        = "Create Symblink"
    #     ScriptPath = "Tools\Create-Symblink.ps1"
    #     Path       = $toolsPath
    #     Icon       = "pwsh.exe"
    # },
    @{
        Extensions    = @("*", "Directory")
        Title         = "Copy"
        Key           = "999 Copy.ps1"
        ScriptPath    = "Tools\Copy-ToDrive.ps1"
        Path          = $toolsPath
        Icon          = "pwsh.exe"
        PathParamName = "-Files"
        AdditionalArgs = @("-CustomDestiniation")
    }, 
    @{
        Extensions    = @("*", "Directory")
        Title         = "Copy To Different Drive With The Same Hierarchy"
        Key           = "999-Copy-ToDrive.ps1"
        ScriptPath    = "Tools\Copy-ToDrive.ps1"
        Path          = $toolsPath
        Icon          = "pwsh.exe"
        PathParamName = "-Files"
    } #, 
    # @{
    #     Extensions     = @("Drive", "*", "Directory", $Recycle)
    #     Title          = "Safe Delete (Prompt For Passes)"
    #     Key            = "999 Safe Delete (Prompt For Passes)"
    #     ScriptPath     = "Tools\Safe-Delete.ps1"
    #     Path           = $safeDelete
    #     Icon           = "pwsh.exe"
    #     AdditionalArgs = @("--prompt", "--promptPasses")
    # },
) 
#endregion

$specialsExtensions = @("*", "Directory", "Drive");
@($scripts | ForEach-Object { return $_.Extensions } | Get-Unique) | ForEach-Object {
    if ($_ -in $specialsExtensions) {
        reg delete "HKEY_CURRENT_USER\Software\Classes\$_\shell\0 Scripts" /f;
    }
    else {
        reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\$_\shell\0 Special Scripts" /f;
    }
};

$scripts | ForEach-Object {
    $element = $_;
    $extensions = $element.Extensions;
    foreach ($extension in $extensions) {
        $base = "";
        $title = "";
        if ($extension -in $specialsExtensions) {
            $base = "HKEY_CURRENT_USER\Software\Classes\$extension\shell\0 Scripts";
            $title = "Scripts";
        }
        elseif ($extension -eq $Recycle) {
            $base = "HKEY_CLASSES_ROOT\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\shell\0 Scripts";
            $title = "Scripts";
        }
        else {
            $base = "HKEY_CLASSES_ROOT\SystemFileAssociations\$extension\shell\0 Special Scripts";
            $title = "Special Scripts";
        }

        CreateMenu -base $base -title $title;
        Handle -base "$base\shell" -element $element -extension $extension;
    }
};

Write-Host "Done" -ForegroundColor Green;
timeout.exe 5;