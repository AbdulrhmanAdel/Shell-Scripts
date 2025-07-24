
#region Helpers
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
        [object[]]$Arguments = @()
    )

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
    
    Write-Host "===========================" ;
    Write-Host "Running $Path" ;
    if ($NoWait) {
        Start-Process -File $Path -Verb RunAs -ArgumentList $Arguments;
    }
    else {
        Start-Process -File $Path -Verb RunAs -ArgumentList $Arguments -Wait;
    }
    Write-Host "Done" ;
    Write-Host "===========================" ;
}

#endregion

# region Setup Personal Projects
if (!$ShellProjectPath) {
    Write-Host "Please Select ShellProjectPath" -ForegroundColor Green
    $ShellProjectPath = Folder-Picker.ps1 -InitialDirectory "D:\" -ShowOnTop;
}

RunPowershell "$ShellProjectPath\Setup-EnvironmentVariable.ps1" -NoTimeout;
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User");
RunPowershell -Path "$ShellProjectPath\Setup-ContextMenu.ps1" -AdditionalArgs @("-NoTimeout")
RunPowershell -Path "$ShellProjectPath\Setup-SendToMenu.ps1" -AdditionalArgs @("-NoTimeout")
# #endregion

# # region Programming
if (!$ProgrammingPath) {
    Write-Host "Please Select ProgrammingPath" -ForegroundColor Green
    $ProgrammingPath = Folder-Picker.ps1 -ShowOnTop;
}
Add-ToPath.ps1 -Paths @(
    "$ProgrammingPath\Binaries"
);
RunPowershell -Path "$configPath\Dotnet\Register.ps1";
RunPowershell -Path "$configPath\Git\Register.ps1";
RunPowershell -Path "$configPath\Node\Register.ps1";
RunPowershell -Path "$configPath\JetBrains\Register.ps1";
RunPowershell -Path "$configPath\VsCode\Register.ps1";
# #endregion

# # region Programs
if (!$ProgramsPath) {
    Write-Host "Please Select ProgramsPath" -ForegroundColor Green
    $ProgramsPath = Folder-Picker.ps1 -ShowOnTop;
}

$tweakspath = "$ProgramsPath\Operating System\Windows\Tweaks"
RunProgram -Path "$tweakspath\Shells\NileSoft\shell.exe" -Arguments @("-register", "-restart");
RunPowershell -Path "$tweaksPath\Enable-DotNet3.5Framework.ps1";
RunReg -Path "$tweaksPath\Power Plan\Show-TurboBoost.reg"
RunReg -Path "$tweaksPath\Set-Powershell7AsDefault.reg"
RunPowershell -Path "$tweaksPath\StartMenu\Sync-StartMenu.ps1" -AdditionalArgs @("-Process", "Restore");
RunPowershell -Path "$tweaksPath\Hib\Disable-Hib.ps1"
RunCmd -Path "$tweaksPath\Date And Time\Change-DateFormat.bat"

RunProgram -Path (AppRegexSelector -ParentPath "$ProgramsPath\Utilities" -Regex "PowerToysUserSet");
RunPowershell -Path "$ProgramsPath\Media\Players\K-Lite\Register.ps1";
RunPowershell -Path "$ProgramsPath\Storage & Data\Compress\7-Zip\Set-AsDefault.ps1";

# IDM
RunPowershell -Path "$ProgramsPath\Net\Downloaders\IDM\Register.ps1";
RunPowershell -Path "$ProgramsPath\\Net\Torrent\qBittorrent\Register.ps1";

#region hardware Monitor
RunPowershell -Path "$ProgramsPath\Hardware\Monitor\HWiNFO64\HWiNFO64.ps1" -AdditionalArgs @("-Process", "Restore", "-NoTimeout");
RunProgram -Path "$ProgramsPath\Hardware\Monitor\HWiNFO64\HWiNFO64.exe" -NoWait;
RunProgram -Path "$ProgramsPath\Hardware\Monitor\RivaTuner Statistics Server\RTSS.exe" -NoWait;

#endregion
RunPowershell -Path "$ProgramsPath\Tools\MEGAsync\Data\Link.ps1";

#region Games
$gamesPath = "$ProgramsPath\Games";
RunCmd -Path "$gamesPath\C++ Runtimes\install_all.bat"
RunProgram -Path "$gamesPath\DirectX\DXSETUP.exe" -Arguments @("/silent");
RunProgram -Path "$gamesPath\Epic Games\Epic Online Services\EpicOnlineServices.exe"
RunProgram -Path "$gamesPath\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
#endregion

& "$ShellProjectPath\Add-ToPath.ps1" -Paths @(
    "$ProgramsPath\Binaries"
) -NoTimeout;

Write-Host "Setup Completed Successfully" -ForegroundColor Green;
timeout.exe 10;