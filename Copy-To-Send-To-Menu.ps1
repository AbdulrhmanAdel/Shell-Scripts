[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $NoTimeout
)
& Run-AsAdmin.ps1 -Arguments @($NoTimeout ? '-NoTimeout' : '');
# Install-Package SharpShell;

Write-Host "Copying To Send To Menu" -ForegroundColor Green;
$sendToMenuFolder = "$($env:APPDATA)\Microsoft\Windows\SendTo";
$scriptPath = $PSScriptRoot;
#region Menu
$menu = @(
    @{
        Name      = "01- Media Scripts.lnk"
        Arguments = "-File ""$scriptPath\Media\Module.ps1"""
    },
    @{
        Name      = "02- Subtitle Scripts.lnk"
        Arguments = "-File ""$scriptPath\Subtitles\Module.ps1"""
    },
    @{
        Name      = "03- General Tools.lnk"
        Arguments = "-File ""$scriptPath\Tools\Module.ps1"""
    }
    # @{
    #     Name      = "500- Copy To Different Drive With The Same Hierarchy.lnk"
    #     Arguments = "-File ""$scriptPath\Tools\Copy-To-Different-Drive-With-The-Same-Hierarchy.ps1"""
    # },
)
     
#endregion
Remove-Item -LiteralPath $sendToMenuFolder -Force -Recurse;
if (!(Test-Path -LiteralPath $sendToMenuFolder)) {
    New-Item -Path $sendToMenuFolder -ItemType Directory -Force | Out-Null;
}

$menu | ForEach-Object {
    $sh = New-Object -ComObject WScript.Shell
    $path = "$sendToMenuFolder/$($_.Name)";
    $shortCut = $sh.CreateShortcut($path);
    $shortCut.TargetPath = "pwsh.exe";
    $shortCut.Arguments = "-WindowStyle Maximized $($_.Arguments)";
    $shortCut.Save();
}

if ($NoTimeout) {
    Exit;
}

Write-Host "Done" -ForegroundColor Green;
timeout.exe 5;