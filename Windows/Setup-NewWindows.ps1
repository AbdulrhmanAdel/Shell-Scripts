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
$ShellProjectPath = (Resolve-Path "$PSScriptRoot/..").ToString();
if (!$ShellProjectPath -or -not (Test-Path -LiteralPath $ShellProjectPath)) {
    Write-Host "Please Select ShellProjectPath" -ForegroundColor Green
    $ShellProjectPath = Folder-Picker.ps1 -InitialDirectory "D:\" -ShowOnTop;
}

RunPowershell "$ShellProjectPath\Setup-EnvironmentVariable.ps1" -NoTimeout;
$env:Path += ";" + [System.Environment]::GetEnvironmentVariable("Path", "User");
RunPowershell -Path "$ShellProjectPath\Setup-ContextMenu.ps1" -AdditionalArgs @("-NoTimeout")
RunPowershell -Path "$ShellProjectPath\Setup-SendToMenu.ps1" -AdditionalArgs @("-NoTimeout")
# #endregion

# region Programs: each programs folder has a " Maintenance\Setup.ps1" for its own apps
foreach ($setupPath in @("D:\Programs\ Maintenance\Setup.ps1", "D:\Programming\Programs\ Maintenance\Setup.ps1")) {
    if (!(Test-Path -LiteralPath $setupPath)) {
        Write-Host "Please select the programs folder for $setupPath" -ForegroundColor Green
        $setupPath = Join-Path (Folder-Picker.ps1 -ShowOnTop) " Maintenance\Setup.ps1";
    }
    RunPowershell -Path $setupPath;
}
# #endregion

timeout.exe 10;