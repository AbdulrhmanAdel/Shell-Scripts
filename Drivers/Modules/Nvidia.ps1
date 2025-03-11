# [CmdletBinding()]
# param (
#     [Parameter(Mandatory = $true)]
#     [string]
#     $OsVersion,
#     [Parameter(Mandatory = $true)]
#     [string]
#     $OsArchitecture
# )


#region Functions
function GetHardwareInfo {
    try {
        $VideoController = Get-WmiObject -ClassName Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }
        $installedVersionDetails = [double]($VideoController.DriverVersion.Replace('.', '')[-5..-1] -join '').insert(3, '.')
        return @{
            Version = $installedVersionDetails
            Name    = $VideoController.Name
        }
    }
    catch {
        return $null;
    }
}

#endregion

$installedVersionDetails = GetHardwareInfo;
if (!$installedVersionDetails) {
    Write-Host -ForegroundColor Yellow "Unable to detect a compatible Nvidia device."
    Write-Host "Press any key to exit..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

$osID = 135;
$driverFamilyId = 123
$driverId = 963;

$res = curl "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=$driverFamilyId&pfid=$driverId&osID=$osID&languageCode=1033&beta=null&isWHQL=1&dltype=-1&dch=1&upCRD=null&qnf=0&ctk=null&sort1=1&numberOfResults=1" | ConvertFrom-Json;
$version = [double]$res.IDS[0].downloadInfo.Version;
if (!$installedVersionDetails.Version -or $installedVersionDetails.Version -lt $version) {
    Write-Host "New version available: $version"
}

$url = $res.IDS[0].downloadInfo.DownloadURL;
Start-Process $url ;