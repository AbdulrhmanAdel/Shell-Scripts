if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $callStack = Get-PSCallStack
    $Path = $callStack[1].ScriptName
    $processArguments = @(
        "-File", """$Path"""
    );

    Start-Process powershell.exe -Verb RunAs -ArgumentList $processArguments;
    [Environment]::Exit(0);
}

# region Helpers

function CreateShortcut {
    param (
        $Target,
        $Source
    )
    
    & "D:\Programming\Projects\Personal Projects\Shell-Scripts\Shared\Create-Shortcut.ps1" `
        -Target $Target `
        -Source $Source
}

function RunPowershell {
    param (
        $Path
    )
    Write-Host "===========================" -BackgroundColor Red;
    Write-Host "Running $Path" -BackgroundColor Green;
    & "$Path";
    Write-Host "Done" -BackgroundColor Green;
    Write-Host "===========================" -BackgroundColor Red;
}

function RunReg {
    param (
        $Path
    )

    Write-Host "===========================" -BackgroundColor Red;
    Write-Host "Running $Path" -BackgroundColor Green;
    reg import "$Path";
    Write-Host "Done" -BackgroundColor Green;
    Write-Host "===========================" -BackgroundColor Red;
}

function RunCmd {
    param (
        $Path
    )
    
    Write-Host "===========================" -BackgroundColor Red;
    Write-Host "Running $Path" -BackgroundColor Green;
    & "$Path";
    Write-Host "Done" -BackgroundColor Green;
    Write-Host "===========================" -BackgroundColor Red;
}


function RunProgram {
    param (
        $Path,
        [switch]$NoWait
    )

    Write-Host "===========================" -BackgroundColor Red;
    Write-Host "Running $Path" -BackgroundColor Green;
    if ($NoWait) {
        Start-Process $Path -Verb RunAs;
    }
    else {
        Start-Process $Path -Verb RunAs -Wait;
    }
    Write-Host "Done" -BackgroundColor Green;
    Write-Host "===========================" -BackgroundColor Red;

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
RunPowershell -Path "$programmingPath\1- Programs Data\Link.ps1";

RunProgram -Path "$programmingPath\Git\Git-2.46.2-64-bit.exe";
RunProgram -Path "$programmingPath\Node\node-v22.0.0-x64.msi";
# #endregion

# # region Programs
$programsPath = "D:\Programs";
$tweakspath = "$programsPath\Windows\Tweaks"
# .Net
Invoke-Item -LiteralPath "D:\Programs\OS\Windows\Win11_24H2_English_x64.iso";
RunPowershell -Path "$tweaksPath\Enable-DotNet3.5Framework.ps1";
RunCmd -Path "$programsPath\C++ Runtimes\install_all.bat"
RunProgram -Path "$programsPath\Games\DirectX\DXSETUP.exe";
RunReg -Path "$tweaksPath\Show-Turbo Boost.reg"
RunReg -Path "$tweaksPath\Fix powershell files whitespace issue.reg"
RunPowershell -Path "$tweaksPath\Toggle-HiddenFiles.ps1"
RunPowershell -Path "$tweaksPath\StartMenu\Restore.ps1"
RunPowershell -Path "$tweaksPath\Hib\Disable-Hib.ps1"
RunCmd -Path "$tweaksPath\Date And Time\Change-DateFormat.bat"

RunProgram -Path "$programsPath\Microsoft\PowerShell-7.4.4-win-x64.msi";
RunProgram -Path "$programsPath\Microsoft\PowerToysUserSetup-0.85.0-x64.exe";
RunProgram -Path "$programsPath\Media\K-Lite\K-Lite_Codec_Pack_1855_Mega.exe";
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
RunProgram -Path "$programsPath\Net\Torrent\qBittorrent\Data\Assign-QBittorrentToOpenTorrentFiles.reg" -NoWait;

RunProgram -Path "$programsPath\Hardware\HWiNFO64\HWiNFO64.exe" -NoWait;
RunProgram -Path "$programsPath\Hardware\RivaTuner Statistics Server\RTSS.exe" -NoWait;

#endregion

