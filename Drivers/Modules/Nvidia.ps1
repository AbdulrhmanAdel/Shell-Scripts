# [CmdletBinding()]
# param (
#     [Parameter(Mandatory = $true)]
#     [string]
#     $OsVersion,
#     [Parameter(Mandatory = $true)]
#     [string]
#     $OsArchitecture
# )

$FamilyList = @(
    @{
        Key      = "GeForce RTX 50 Series (Notebooks)"
        FamilyId = 133
    },
    @{
        Key      = "GeForce RTX 50 Series"
        FamilyId = 131
    },
    @{
        Key      = "GeForce RTX 40 Series (Notebooks)"
        FamilyId = 129
        Drivers  = @(
            @{
                Key      = "GeForce RTX 4090 Laptop GPU"
                DriverId = 1004
            },
            @{
                Key      = "GeForce RTX 4080 Laptop GPU"
                DriverId = 1005
            },
            @{
                Key      = "GeForce RTX 4070 Laptop GPU"
                DriverId = 1006
            },
            @{
                Key      = "GeForce RTX 4060 Laptop GPU"
                DriverId = 1007
            },
            @{
                Key      = "GeForce RTX 4050 Laptop GPU"
                DriverId = 1008
            }
        );
    },
    @{
        Key      = "GeForce RTX 40 Series"
        FamilyId = 127
        Drivers  = @(
            @{
                Key      = "NVIDIA GeForce RTX 4070 Super"
                DriverId = 1039
            }
        )
    },
    @{
        Key      = "GeForce RTX 30 Series (Notebooks)"
        FamilyId = 123
        Drivers  = @(
            @{
                Key      = "NVIDIA GeForce RTX 3050 Laptop GPU"
                DriverId = 963
            }
        )
    },
    @{
        Key      = "GeForce RTX 30 Series"
        FamilyId = 120
    },
    @{
        Key      = "GeForce RTX 20 Series (Notebooks)"
        FamilyId = 111
    },
    @{
        Key      = "GeForce RTX 20 Series"
        FamilyId = 107
    }
    # @{
    #     Key   = "GeForce MX500 Series (Notebooks)"
    #     FamilyId = 125
    # },
    # @{
    #     Key   = "GeForce MX400 Series (Notebooks)"
    #     FamilyId = 121
    # },
    # @{
    #     Key   = "GeForce MX300 Series (Notebooks)"
    #     FamilyId = 117
    # },
    # @{
    #     Key   = "GeForce MX200 Series (Notebooks)"
    #     FamilyId = 113
    # },
    # @{
    #     Key   = "GeForce MX100 Series (Notebook)"
    #     FamilyId = 104
    # },
    # @{
    #     Key   = "GeForce GTX 16 Series (Notebooks)"
    #     FamilyId = 115
    # },
    # @{
    #     Key   = "GeForce 16 Series"
    #     FamilyId = 112
    # },
    # @{
    #     Key   = "GeForce 10 Series"
    #     FamilyId = 101
    # },
    # @{
    #     Key   = "GeForce 10 Series (Notebooks)"
    #     FamilyId = 102
    # },
    # @{
    #     Key   = "GeForce 900 Series"
    #     FamilyId = 98
    # },
    # @{
    #     Key   = "GeForce 900M Series (Notebooks)"
    #     FamilyId = 99
    # },
    # @{
    #     Key   = "GeForce 800M Series (Notebooks)"
    #     FamilyId = 97
    # },
    # @{
    #     Key   = "GeForce 700M Series (Notebooks)"
    #     FamilyId = 92
    # },
    # @{
    #     Key   = "GeForce 700 Series"
    #     FamilyId = 95
    # },
    # @{
    #     Key   = "GeForce 600 Series"
    #     FamilyId = 85
    # },
    # @{
    #     Key   = "GeForce 600M Series (Notebooks)"
    #     FamilyId = 84
    # },
    # @{
    #     Key   = "GeForce 500 Series"
    #     FamilyId = 76
    # },
    # @{
    #     Key   = "GeForce 500M Series (Notebooks)"
    #     FamilyId = 78
    # },
    # @{
    #     Key   = "GeForce 400 Series"
    #     FamilyId = 71
    # },
    # @{
    #     Key   = "GeForce 400M Series (Notebooks)"
    #     FamilyId = 72
    # },
    # @{
    #     Key   = "GeForce 300 Series"
    #     FamilyId = 70
    # },
    # @{
    #     Key   = "GeForce 300M Series (Notebooks)"
    #     FamilyId = 69
    # },
    # @{
    #     Key   = "GeForce 200 Series"
    #     FamilyId = 52
    # },
    # @{
    #     Key   = "GeForce 200M Series (Notebooks)"
    #     FamilyId = 62
    # },
    # @{
    #     Key   = "GeForce 100 Series"
    #     FamilyId = 59
    # },
    # @{
    #     Key   = "GeForce 100M Series (Notebooks)"
    #     FamilyId = 61
    # },
    # @{
    #     Key   = "GeForce 9 Series"
    #     FamilyId = 51
    # },
    # @{
    #     Key   = "GeForce 9M Series (Notebooks)"
    #     FamilyId = 53
    # },
    # @{
    #     Key   = "GeForce 8 Series"
    #     FamilyId = 1
    # },
    # @{
    #     Key   = "GeForce 8M Series (Notebooks)"
    #     FamilyId = 54
    # },
    # @{
    #     Key   = "GeForce 7 Series"
    #     FamilyId = 2
    # },
    # @{
    #     Key   = "GeForce Go 7 Series (Notebooks)"
    #     FamilyId = 55
    # },
    # @{
    #     Key   = "GeForce 6 Series"
    #     FamilyId = 3
    # },
    # @{
    #     Key   = "GeForce 5 FX Series"
    #     FamilyId = 4
    # }
)
 
#region Functions
function GetHardwareInfo {
    $VideoController = Get-WmiObject -ClassName Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }
    if (!$VideoController) {
        return $null;
    }
    
    $name = $VideoController.Name;
    $installedVersionDetails = [double]($VideoController.DriverVersion.Replace('.', '')[-5..-1] -join '').insert(3, '.')
    $DriverInfo = $FamilyList | ForEach-Object { 
        $F = $_;
        if (!$F.Drivers) {
            return @();
        }
        return $F.Drivers | ForEach-Object {
            $_.FamilyId = $F.FamilyId;
            return $_;
        }
    } | Where-Object {
        $_.Key -eq $name
    } | Select-Object -First 1;

    return @{
        Version          = $installedVersionDetails
        NvidiaDriverInfo = $DriverInfo
    }
}

#endregion
$driverInfo = $null;
$installedHardwareInfo = GetHardwareInfo;
if (!$installedHardwareInfo -or !$installedHardwareInfo.NvidiaDriverInfo) {
    Write-Host -ForegroundColor Red "Unable to detect a compatible Nvidia device."
    Write-Host -ForegroundColor Yellow "Switching to manual mode, Please select your Nvidia device from the list below:"
    $driverFamily = Single-Options-Selector.ps1 -Options $FamilyList;
    $driverInfo = Single-Options-Selector.ps1 -Options $driverFamily.Drivers;
    $driverInfo.FamilyId = $driverFamily.FamilyId
}
else {
    $driverInfo = $installedHardwareInfo.NvidiaDriverInfo;
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
# if (Prompt.ps1 -Message "Do you want manually download and update the driver?") {
#     Start-Process $url;
#     Exit;
# }

$DriverName = Split-Path $url -Leaf
$DriverPath = "$($env:USERPROFILE)\Downloads\$DriverName";
if (-not (Test-Path -LiteralPath $DriverPath)) {
    Write-Host "Downloading the latest version to $DriverPath"
    Invoke-WebRequest $url -OutFile $DriverPath;
    Invoke-Item -LiteralPath "$($env:USERPROFILE)\Downloads";
}

Write-Host "Extracting the driver to $DriverPath, Please insure 7zip is installed and added to Path"
$extractPath = "$($env:TEMP)\NvidiaDriver\$version";
if (-not (Test-Path -LiteralPath $DriverPath)) {

    Start-Process 7z.exe -ArgumentList @(
        "x", 
        """$($DriverPath)""",
        "-o$extractPath"
    ) -NoNewWindow -PassThru -Wait;
}

$install_args = "-passive -noreboot -noeula -nofinish -s -clean"
Start-Process -FilePath "$extractPath\setup.exe" -ArgumentList $install_args -wait;
Write-Host "Driver installation completed successfully."
if (Prompt.ps1 -Message "Do you want to reboot now?") {
    Start-Sleep -Seconds 5;
    Restart-Computer -Force;
}