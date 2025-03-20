# [CmdletBinding()]
# param (
#     [Parameter(Mandatory = $true)]
#     [string]
#     $OsVersion,
#     [Parameter(Mandatory = $true)]
#     [string]
#     $OsArchitecture
# )

$driverList = @(
    @{
        Key      = "NVIDIA GeForce RTX 3050 Laptop"
        FamilyId = 123
        DriverId = 963
    }
    @{
        Key      = "NVIDIA GeForce RTX 4070 Super"
        FamilyId = 127
        DriverId = 1039
    }
)

#region Functions
function GetHardwareInfo {
    $VideoController = Get-WmiObject -ClassName Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }
    if (!$VideoController) {
        return $null;
    }
    
    $name = $VideoController.Name;
    $installedVersionDetails = [double]($VideoController.DriverVersion.Replace('.', '')[-5..-1] -join '').insert(3, '.')
    return @{
        Version = $installedVersionDetails
        Info    = $driverList | `
            Where-Object { $name.StartsWith($_.Key) } | `
            Select-Object -First 1;
    }
}

#endregion
$driverInfo = $null;
$installedHardwareInfo = GetHardwareInfo;
if (!$installedHardwareInfo) {
    Write-Host -ForegroundColor Red "Unable to detect a compatible Nvidia device."
    Write-Host -ForegroundColor Yellow "Switching to manual mode, Please select your Nvidia device from the list below:"
    $driverInfo = Single-Options-Selector.ps1 -Options $driverList;
}
else {
    $driverInfo = $installedHardwareInfo.Info;
}

$osID = 135; # Windows 10 and 11 Code
$driverFamilyId = $driverInfo.FamilyId
$driverId = $driverInfo.DriverId;
$res = curl "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=$driverFamilyId&pfid=$driverId&osID=$osID&languageCode=1033&beta=null&isWHQL=1&dltype=-1&dch=1&upCRD=null&qnf=0&ctk=null&sort1=1&numberOfResults=1" | ConvertFrom-Json;
$downloadInfo = $res.IDS[0].downloadInfo;
$version = [double]$downloadInfo.Version;
if (!$installedHardwareInfo.Version -or $installedVersionDetails.Version -lt $version) {
    Write-Host "New version available: $version"
}

$url = $downloadInfo.DownloadURL;
Start-Process $url ;