$Options = @(
    @{
        Key     = "Nvidia"
        Handler = {
            & "$PSScriptRoot/Modules/Nvidia.ps1";
        }
    }
)

(Multi-Options-Selector.ps1 -options $Options) | ForEach-Object {
    Write-Host "Updating $($_.Name) driver" 
    $_.Handler.Invoke();
};