Run-AsAdmin.ps1;
# region Helpers

function RunPowershell {
    param (
        $Path,
        $AdditionalArgs
    )
    Write-Host "===========================" ;
    Write-Host "Running $Path";

    $ProcessArgs = @("-File", """$Path""");
    if ($AdditionalArgs) {
        $ProcessArgs += $AdditionalArgs;
    }
    Start-Process pwsh -ArgumentList $ProcessArgs -Wait -NoNewWindow;
    Write-Host "Done" ;
    Write-Host "===========================" ;
}

function RunReg {
    param (
        $Path
    )

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
    if ($NoAdmin) {
        Start-Process -File $Path -Wait;
    }
    elseif ($NoWait) {
        Start-Process -File $Path -Verb RunAs;
    }
    else {
        Start-Process -File $Path -Verb RunAs -Wait;
    }
    Write-Host "Done" ;
    Write-Host "===========================" ;
}
#endregion

# region Setup Personal Projects
$personalProjectPath = $PSScriptRoot;
RunPowershell -Path "$personalProjectPath\Add-Shared-To-Path.ps1"
RunPowershell -Path "$personalProjectPath\Add-To-Context-Menu.ps1"
RunPowershell -Path "$personalProjectPath\Copy-To-Send-To-Menu.ps1"
# #endregion

# # region Programming
$programmingPath = "D:\Programming\Programs";
RunReg -Path "$programmingPath\1- Regisy Programs\VsCode.reg";
RunReg -Path "$programmingPath\1- Regisy Programs\WebStorm.reg";
RunReg -Path "$programmingPath\1- Regisy Programs\Rider.reg";
RunReg -Path "$programmingPath\1- Regisy Programs\Terminal.reg";
RunReg -Path "$programmingPath\1- Regisy Programs\Add-IDEsToUserEnvPath.ps1";
RunPowershell -Path "$programmingPath\1- Programs Data\Link.ps1";

RunProgram -Path "$programmingPath\Git\Git-2.46.2-64-bit.exe";
RunProgram -Path "$programmingPath\Node\node-v22.9.0-x64.msi";
# #endregion

# # region Programs
$programsPath = "D:\Programs";
$tweakspath = "$programsPath\Windows\Tweaks"
# .Net
Invoke-Item -LiteralPath "D:\Programs\OS\Windows\Win11_24H2_English_x64.iso";
RunPowershell -Path "$tweaksPath\Enable-DotNet3.5Framework.ps1";
RunCmd -Path "$programsPath\C++ Runtimes\install_all.bat"
RunReg -Path "$tweaksPath\Power Plan\Show-TurboBoost.reg"
RunReg -Path "$tweaksPath\Fix powershell files whitespace issue.reg"
RunPowershell -Path "$tweaksPath\StartMenu\Sync-StartMenu.ps1" -AdditionalArgs @("-Process", "Restore", "-NoTimeout");
RunPowershell -Path "$tweaksPath\Hib\Disable-Hib.ps1"
RunCmd -Path "$tweaksPath\Date And Time\Change-DateFormat.bat"

RunProgram -Path "$programsPath\Microsoft\PowerShell-7.4.4-win-x64.msi";
RunProgram -Path "$programsPath\Microsoft\PowerToysUserSetup-0.85.0-x64.exe";
RunProgram -Path "$programsPath\Media\K-Lite\K-Lite_Codec_Pack.exe";
RunPowershell -Path "$programsPath\Media\K-Lite\K-Lite.ps1" -AdditionalArgs @("-Process", "Restore", "-NoTimeout");
RunProgram -Path "$programsPath\Compress\7-Zip\7zFM.exe";

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
    "$programsPath\Compress\7-Zip"
);
[Environment]::SetEnvironmentVariable('Path', $pathes -join ";", [EnvironmentVariableTarget]::User);


