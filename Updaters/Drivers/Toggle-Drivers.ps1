Run-AsAdmin.ps1;

# List all PnP devices
$drivers = @(Get-PnpDevice -FriendlyName "");
$drivers | Foreach-Object {
    if ($_.Status -eq "OK") {
        Write-Host "Disabling driver: $($_.FriendlyName)"
        Disable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false
    }
    else {
        Write-Host "Enabling driver: $($_.FriendlyName)"
        Enable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false
    }
}