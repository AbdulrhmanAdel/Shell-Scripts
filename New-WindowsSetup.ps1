[CmdletBinding()]
param (
    [string[]]
    $IgnoreScripts = @(),
    [switch]
    $AddToShared = $true
)

Run-AsAdmin.ps1 -Arguments @(
    "-IgnoreScripts", $IgnoreScripts
);
# region Helpers

function AppRegexSelector {
    param (
        $ParentPath,
        $Regex
    )

    $Path = Get-ChildItem -LiteralPath $ParentPath | Where-Object { $_.Name -match $Regex } | Select-Object -First 1;
    if ($Path) {
        return $Path.FullName;
    }
    else {
        Write-Host "No File Found for $Regex Parent With $ParentPath" -ForegroundColor Red;
        return;
    } 
    
}
function RunPowershell {
    param (
        $Path,
        $AdditionalArgs
    )

    if ($IgnoreScripts -contains "pwsh") {
        Write-Host "Skipping $Path" -ForegroundColor Yellow;
        return;
    }
    
    Write-Host "===========================" ;
    Write-Host "Running $Path";

    $ProcessArgs = @("-File", """$Path""", "-NoTimeout");
    if ($AdditionalArgs) {
        $ProcessArgs += $AdditionalArgs;
    }

    $ProcessArgs = @($ProcessArgs | Select-Object -Unique);
    Start-Process pwsh -ArgumentList $ProcessArgs -Wait -NoNewWindow;
    Write-Host "Done" ;
    Write-Host "===========================" ;
}

function RunReg {
    param (
        $Path
    )

    if ($IgnoreScripts -contains "reg") {
        Write-Host "Skipping $Path" -ForegroundColor Yellow;
        return;
    }
    

    Write-Host "===========================" ;
    Write-Host "Running $Path" ;
    reg import "$Path";
    Write-Host "Done" ;
    Write-Host "===========================" ;
}

function RunCmd {
    param (
        $Path
    )

    if ($IgnoreScripts -contains "cmd") {
        Write-Host "Skipping $Path" -ForegroundColor Yellow;
        return;
    }
    
    
    Write-Host "===========================" ;
    Write-Host "Running $Path" ;
    & "$Path";
    Write-Host "Done" ;
    Write-Host "===========================" ;
}


$installedPrograms = Get-CimInstance -ClassName Win32_Product;
function RunProgram {
    param (
        $Path,
        [switch]$NoWait,
        [switch]$NoAdmin
    )
    
    if ($IgnoreScripts -contains "program") {
        Write-Host "Skipping $Path" -ForegroundColor Yellow;
        return;
    }
    

    if (!$NoWait) {
        $InstallSource = (Split-Path -LiteralPath $Path) + "\";
        $PackageName = Split-Path $Path -Leaf;
        $isInstalled = $installedPrograms | Where-Object { 
            $InstallSource -eq $_.InstallSource -or `
                $PackageName -eq $_.PackageName
        }
        if ($isInstalled) {
            Write-Host "Program $Path Already Installed" -ForegroundColor Red;
            return;
        }
    }

    Write-Host "===========================" ;
    Write-Host "Running $Path" ;
    $isMSIPackage = $Path -match "\.msi$";
    if ($NoAdmin) {
        if ($isMSIPackage) {
            Start-Process -File msiexec.exe -ArgumentList "/i `"$Path`"", "/qn" -Wait;
            return
        }
        Start-Process -File $Path -Wait;
    }
    elseif ($NoWait) {
        if ($isMSIPackage) {
            Start-Process -File msiexec.exe -ArgumentList "/i `"$Path`"", "/qn" -Verb RunAs;
            return
        }
        Start-Process -File $Path -Verb RunAs;
    }
    else {
        if ($isMSIPackage) {
            Start-Process -File msiexec.exe -ArgumentList "/i `"$Path`"", "/qn" -Verb RunAs -Wait;
            return
        }
        Start-Process -File $Path -Verb RunAs -Wait;
    }
    Write-Host "Done" ;
    Write-Host "===========================" ;
}
#endregion

# region Setup Personal Projects
$personalProjectPath = $PSScriptRoot;

if ($AddToShared) {
    RunPowershell -Path "$personalProjectPath\Add-SharedToPath.ps1" -AdditionalArgs @("-NoTimeout")
    Start-Process pwsh.exe -ArgumentList @(
        "-File", "$PSScriptRoot\New-WindowsSetup.ps1"
    )
    Exit;
}

RunPowershell -Path "$personalProjectPath\Setup-ContextMenu.ps1" -AdditionalArgs @("-NoTimeout")
RunPowershell -Path "$personalProjectPath\Setup-SendToMenu.ps1" -AdditionalArgs @("-NoTimeout")
# #endregion


# # region Programming
$programmingPath = "D:\Programming\Programs";
$configPath = "$programmingPath\ Configuration";
RunReg -Path "$configPath\Scripts\VsCode.reg";
RunReg -Path "$configPath\Scripts\WebStorm.reg";
RunReg -Path "$configPath\Scripts\Rider.reg";
RunReg -Path "$configPath\Scripts\Terminal.reg";
RunReg -Path "$configPath\Scripts\Add-ToPath.ps1";
RunPowershell -Path "$configPath\Programs Data\Link.ps1";

RunProgram -Path (AppRegexSelector -ParentPath "$programmingPath\Git" -Regex "^Git.*bit\.exe$");
RunProgram -Path (AppRegexSelector -ParentPath "$programmingPath\Node" -Regex "^node.*msi$");
# #endregion

# # region Programs
$programsPath = "D:\Programs";
$tweakspath = "$programsPath\Operating System\Windows\Tweaks"
# .Net
Invoke-Item -LiteralPath "$programsPath\Operating System\Windows\Win11_24H2_English_x64.iso";
RunPowershell -Path "$tweaksPath\Enable-DotNet3.5Framework.ps1";
RunReg -Path "$tweaksPath\Power Plan\Show-TurboBoost.reg"
RunReg -Path "$tweaksPath\Fix powershell files whitespace issue.reg"
RunPowershell -Path "$tweaksPath\StartMenu\Sync-StartMenu.ps1" -AdditionalArgs @("-Process", "Restore");
RunPowershell -Path "$tweaksPath\Hib\Disable-Hib.ps1"
RunCmd -Path "$tweaksPath\Date And Time\Change-DateFormat.bat"

RunProgram -Path (AppRegexSelector -ParentPath "$programsPath\Utilities" -Regex "PowerToysUserSet");
RunProgram -Path "$programsPath\Media\Players\K-Lite\K-Lite_Codec_Pack.exe";
RunPowershell -Path "$programsPath\Media\Players\K-Lite\K-Lite.ps1" -AdditionalArgs @("-Process", "Restore");
RunProgram -Path "$programsPath\Storage & Data\Compress\7-Zip\7zFM.exe";

# IDM
RunPowershell -Path "$programsPath\Net\Downloaders\IDM\Data\Import-IDM-Registery.ps1";
RunPowershell -Path "$programsPath\Net\Downloaders\IDM\Data\Link-IDMDataFolder.ps1";
RunReg -Path "$programsPath\Net\Downloaders\IDM\Data\Register-Native-Messaging.reg"
RunProgram -Path "$programsPath\Net\Downloaders\IDM\IDMan.exe" -NoWait;


# QBittorrent
RunPowershell -Path "$programsPath\Net\Torrent\qBittorrent\Data\Link-QBitTorrentDataFolder.ps1"
RunReg -Path "$programsPath\Net\Torrent\qBittorrent\Data\Register-QBitTorrentMagnet.reg"
RunReg -Path "$programsPath\Net\Torrent\qBittorrent\Data\Assign-QBittorrentToOpenTorrentFiles.reg"
RunProgram -Path "$programsPath\Net\Torrent\qBittorrent\qbittorrent.exe" -NoWait;

#region hardware Monitor
RunProgram -Path "$programsPath\Hardware\Monitor\HWiNFO64\HWiNFO64.exe" -NoWait;
RunPowershell -Path "$programsPath\Hardware\Monitor\HWiNFO64\HWiNFO64.ps1" -AdditionalArgs @("-Process", "Restore", "-NoTimeout");
RunProgram -Path "$programsPath\Hardware\Monitor\RivaTuner Statistics Server\RTSS.exe" -NoWait;
#endregion
RunProgram -Path "$programsPath\Tools\MEGAsync\MEGAsync.exe" -NoWait;

#region Games
$gamesPath = "$programsPath\Games";
RunProgram -Path "$gamesPath\DirectX\DXSETUP.exe";
RunProgram -Path "$gamesPath\Epic Games\Epic Online Services\EpicOnlineServices.exe"
RunProgram -Path "$gamesPath\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
RunCmd -Path "$gamesPath\C++ Runtimes\install_all.bat"
#endregion


$pathEnvironmentVariable = [Environment]::GetEnvironmentVariable('path', [EnvironmentVariableTarget]::User) ?? "";
$pathes = @($pathEnvironmentVariable -split ";");
$pathes += @(
    "$programsPath\Windows\General Tools"
    "$programsPath\Media\Tools\Ffmpeg\bin"
    "$programsPath\Media\Tools\HandBrake"
    "$programsPath\Media\Tools\MediaInfo"
    "$programsPath\Media\Tools\mkvtoolnix"
    "$programsPath\Media\Tools\yt",
    "$programsPath\Tools\ImageMagick",
    "$programsPath\Storage & Data\Compress\7-Zip"
);
[Environment]::SetEnvironmentVariable('Path', $pathes -join ";", [EnvironmentVariableTarget]::User);