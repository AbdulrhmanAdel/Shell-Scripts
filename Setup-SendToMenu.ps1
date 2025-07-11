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
        Name = "Module Picker"
        Arguments = "-File ""$scriptPath\Shared\Module-Picker.ps1"""
    }
    # @{
    #     Name      = "01- Media Scripts"
    #     Arguments = "-File ""$scriptPath\Media\Module.ps1"""
    # },
    # @{
    #     Name      = "02- Subtitle Scripts"
    #     Arguments = "-File ""$scriptPath\Subtitles\Module.ps1"""
    # },
    # @{
    #     Name      = "03- General Tools"
    #     Arguments = "-File ""$scriptPath\Tools\Module.ps1"""
    # }
)
     
#endregion
Remove-Item -LiteralPath $sendToMenuFolder -Force -Recurse;
if (!(Test-Path -LiteralPath $sendToMenuFolder)) {
    New-Item -Path $sendToMenuFolder -ItemType Directory -Force | Out-Null;
}

$menu | ForEach-Object {
    $sh = New-Object -ComObject WScript.Shell
    $path = "$sendToMenuFolder/$($_.Name).lnk";
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