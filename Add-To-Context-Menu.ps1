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
        Extensions = @(".mp3", ".m4a")
        Title      = "Crop"
        Key        = "999 Crop"
        ScriptPath = "Media\Crop.ps1"
        Path       = $mediaPath
    },
    @{
        Extensions = @("*")
        Title      = "Pin To Start"
        Key        = "Pin To Start"
        ScriptPath = "Tools\Pin-File-To-Start.ps1"
        Path       = $toolsPath
    },
    @{
        Extensions = @("*", "Directory")
        Title      = "TakeOwn"
        Key        = "TakeOwn"
        ScriptPath = "Tools\Takeown.ps1"
        Path       = $toolsPath
    },
    @{
        Extensions = @("Directory")
        Title      = "Add To Envirement Varaibles"
        Key        = "Add To Envirement Varaibles"
        ScriptPath = "Tools\Add-To-Envirement-Varaibles.ps1"
        Path       = $toolsPath
    },
    @{
        Extensions = @("*", "Directory")
        Title      = "Create Symblink"
        Key        = "Create Symblink"
        ScriptPath = "Tools\Create-Symblink.ps1"
        Path       = $toolsPath
    },
    @{
        Extensions = @("Directory")
        Title      = "Single Video"
        Key        = "0 Single Video"
        ScriptPath = "Youtube\Download-Single-video.ps1"
        Path       = $youtubePath
    },
    @{
        Extensions = @("Directory")
        Title      = "Playlist"
        Key        = "1 Playlist"
        ScriptPath = "Youtube\Download-Playlist.ps1"
        Path       = $youtubePath
    }
) 
#endregion

@($scripts | ForEach-Object { return $_.Extensions } | Get-Unique) | ForEach-Object {
    if ($_ -eq "*" -or $_ -eq "Directory") {
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
        if ($extension -eq "*" -or $extension -eq "Directory") {
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

