[CmdletBinding()]
param (
    [ValidateSet("Aria2", "WebRequest")]
    [string]$Downloader
)

Run-AsAdmin.ps1 -Arguments ($Downloader ? @("-Downloader", $Downloader) : @());

$Modules = Get-ChildItem "$PSScriptRoot/Modules/*.ps1" | Where-Object { & $_.FullName -Action Test };
$Updates = @($Modules | ForEach-Object {
        $module = $_;
        & $module.FullName -Action Find | ForEach-Object {
            $_.Module = $module.FullName;
            @{ Key = "[$($module.BaseName)] $($_.Title)"; Value = $_ };
        }
    });

if (!$Updates) {
    Write-Host -ForegroundColor Green "No driver updates found.";
    return;
}

$Selected = @(Multi-Options-Selector.ps1 -Title "Select Drivers" -Options $Updates -SelectedOptions @($Updates | Where-Object { $_.Value.Outdated }));
if (!$Selected) {
    return;
}

$Mode = Single-Options-Selector.ps1 -Title "Select Mode" -Required -Options @(
    @{ Key = "Install"; Value = "Install" },
    @{ Key = "Download Only"; Value = "Download" }
);

if (!$Downloader) {
    $Downloaders = @(
        if ($env:ARIA2_HOME -and (Test-Path -LiteralPath (Join-Path $env:ARIA2_HOME "App\aria2c.exe"))) {
            @{ Key = "Aria2"; Value = "Aria2" }
        }
        @{ Key = "Invoke-WebRequest"; Value = "WebRequest" }
    );
    $Downloader = $Downloaders.Count -gt 1 `
        ? (Single-Options-Selector.ps1 -Title "Select Downloader" -Required -Options $Downloaders -DefaultValue "Aria2") `
        : $Downloaders[0].Value;
}

if ($Mode -eq "Download") {
    $Folder = Folder-Picker.ps1 -Title "Select Download Folder" -InitialDirectory "$env:USERPROFILE\Downloads" -ShowOnTop -Required;
    $Selected | ForEach-Object { & $_.Module -Action Download -Update $_ -Folder $Folder -Downloader $Downloader } | Out-Null;
    Invoke-Item -LiteralPath $Folder;
    return;
}

$Selected | ForEach-Object {
    Write-Host "Installing $($_.Title)";
    & $_.Module -Action Install -Update $_ -Downloader $Downloader;
}

Write-Host -ForegroundColor Green "Driver installation completed.";
if (Prompt.ps1 -Message "Do you want to reboot now?") {
    Start-Sleep -Seconds 5;
    Restart-Computer -Force;
}
