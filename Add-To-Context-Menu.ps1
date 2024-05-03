if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe -Verb RunAs "-Command ""$($MyInvocation.Line)""";
    exit;
}

$baseScriptsPath = $PSScriptRoot;
function BuildScript {
    param (
        [string]$scriptPath,
        [string[]] $additionalArgs
    )

    $finalArgs = "";
    if ($additionalArgs) {
        $finalArgs = ($additionalArgs | ForEach-Object { return """$_""" }) -join " "
    }

    return "pwsh.exe -file ""$baseScriptsPath\$scriptPath"" ""%1"" $finalArgs";
}

function Handle {
    param (
        $base,
        $element
    )
    
    foreach ($path in $element.Path) {
        $base = "$base\$($path.Key)"
        CreateMenu -base "$base" -title $path.Title;
        $base = "$base\shell";
    }

    $key = $element.Key;
    $command = BuildScript -scriptPath $element.ScriptPath -additionalArgs $element.AdditionalArgs;
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

$mediaPath = @(
    @{
        Title = "Media" 
        Key   = "0 Media" 
    }
);

$safeDelete = @(
    @{
        Title = "Delete" 
        Key   = "9999 Delete" 
    }
);

$iconsPath = @(
    @{
        Title = "Icons" 
        Key   = "999999 Icons" 
    }
)

$attributesPath = @(
    @{
        Title = "Attributes"
        Key   = "9999999 Attributes"
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
        Extensions = @("*")
        Title      = "Pin To Start"
        Key        = "Pin To Start"
        ScriptPath = "Tools\Pin-File-To-Start.ps1"
        Path       = $toolsPath
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
        Extensions = @("*", "Directory")
        Title      = "Create Symblink"
        Key        = "Create Symblink"
        ScriptPath = "Tools\Create-Symblink.ps1"
        Path       = $toolsPath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @("*", "Directory")
        Title      = "Copy To Different Drive With The Same Hierarchy"
        Key        = "999-Copy-To-Different-Drive-With-The-Same-Hierarchy"
        ScriptPath = "Tools\Copy-To-Different-Drive-With-The-Same-Hierarchy.ps1"
        Path       = $toolsPath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @("Directory")
        Title      = "Single Video"
        Key        = "0 Single Video"
        ScriptPath = "Youtube\Download-Single-video.ps1"
        Path       = $youtubePath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @("Directory")
        Title      = "Playlist"
        Key        = "1 Playlist"
        ScriptPath = "Youtube\Download-Playlist.ps1"
        Path       = $youtubePath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @("Drive", "*", "Directory")
        Title      = "Safe Delete"
        Key        = "Safe Delete"
        ScriptPath = "Tools\Safe-Delete.ps1"
        Path       = $safeDelete
        Icon       = "pwsh.exe"
        AdditionalArgs = @("--prompt")
    },
    @{
        Extensions = @("Directory")
        Title      = "Set Icon"
        Key        = "Set Icon"
        ScriptPath = "Icons\Set-Folder-Icon.ps1"
        Path       = $iconsPath
        Icon       = "pwsh.exe"
    },
    @{
        Extensions = @("*", "Directory")
        Title      = "Display Attributes"
        Key        = "Display Attributes"
        ScriptPath = "Attributes\Display-Attributes.ps1"
        Path       = $attributesPath
        Icon       = "pwsh.exe"
    }
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
        else {
            $base = "HKEY_CLASSES_ROOT\SystemFileAssociations\$extension\shell\0 Special Scripts";
            $title = "Special Scripts";
        }

        CreateMenu -base $base -title $title;
        Handle -base "$base\shell" -element $element;
    }
};

