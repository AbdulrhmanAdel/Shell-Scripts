# [CmdletBinding()]
# param (
#     [Parameter(Mandatory = $true)]
#     [string]
#     $OsVersion,
#     [Parameter(Mandatory = $true)]
#     [string]
#     $OsArchitecture
# )

$osIdMap = @(
    @{
        OsId = 57
        Name = "Windows 10 64-bit"
    }
    @{
        OsId = 135
        Name = "Windows 11"
    }
    @{
        OsId = 124
        Name = "Linux aarch64"
    }
    @{
        OsId = 12
        Name = "Linux 64-bit"
    }
    @{
        OsId = 22
        Name = "FreeBSD x64"
    }
)

$driverList = @(
    @{
        Key      = "NVIDIA GeForce RTX 5090 D"
        FamilyId = 1
        DriverId = 1067
    }
    @{
        Key      = "NVIDIA GeForce RTX 5090"
        FamilyId = 1
        DriverId = 1066
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
    
    $installedVersionDetails = [double]($VideoController.DriverVersion.Replace('.', '')[-5..-1] -join '').insert(3, '.')
    return @{
        Version = $installedVersionDetails
        Name    = $VideoController.Name
    }
}

#endregion
$driverInfo = $null;
$hardwareInfo = GetHardwareInfo;
if (!$hardwareInfo) {
    Write-Host -ForegroundColor Red "Unable to detect a compatible Nvidia device."
    Write-Host -ForegroundColor Yellow "Switching to manual mode, Please select your Nvidia device from the list below:"
    $driverInfo = Single-Options-Selector.ps1 -Options $driverList;
}
else {
    $driverInfo = $driverList | Where-Object { $_.Key -eq $hardwareInfo.Name } | Select-Object -First 1;
}

$osID = 135;
$driverFamilyId = $driverInfo.FamilyId
$driverId = $driverInfo.DriverId;
$res = curl "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=$driverFamilyId&pfid=$driverId&osID=$osID&languageCode=1033&beta=null&isWHQL=1&dltype=-1&dch=1&upCRD=null&qnf=0&ctk=null&sort1=1&numberOfResults=1" | ConvertFrom-Json;
$downloadInfo = $res.IDS[0].downloadInfo;
$version = [double]$downloadInfo.Version;
if (!$hardwareInfo.Version -or $installedVersionDetails.Version -lt $version) {
    Write-Host "New version available: $version"
}

$url = $downloadInfo.DownloadURL;
Start-Process $url ;