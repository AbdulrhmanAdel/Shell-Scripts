[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateSet("Test", "Find", "Download", "Install")]
    [string]$Action,
    $Update,
    [string]$Folder,
    [ValidateSet("Aria2", "WebRequest")]
    [string]$Downloader = "Aria2"
)

$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36";

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
function Get-Controller {
    return Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" } | Select-Object -First 1;
}

function Get-InstalledDriver {
    $controller = Get-Controller;
    $name = $controller.Name -replace '^NVIDIA\s+', '';
    $driver = foreach ($family in $FamilyList) {
        foreach ($item in $family.Drivers) {
            if (($item.Key -replace '^NVIDIA\s+', '') -eq $name) {
                $item.FamilyId = $family.FamilyId;
                $item;
            }
        }
    }

    return @{
        Version = [double]($controller.DriverVersion.Replace('.', '')[-5..-1] -join '').Insert(3, '.')
        Driver  = $driver | Select-Object -First 1
    }
}

function Select-Driver {
    Write-Host -ForegroundColor Red "Unable to detect a compatible Nvidia device.";
    Write-Host -ForegroundColor Yellow "Switching to manual mode, Please select your Nvidia device from the list below:";
    $family = Single-Options-Selector.ps1 -Title "Select Nvidia Family" -Required -Options @($FamilyList | Where-Object { $_.Drivers });
    $driver = Single-Options-Selector.ps1 -Title "Select Nvidia GPU" -Required -Options $family.Drivers;
    $driver.FamilyId = $family.FamilyId;
    return $driver;
}

function Get-LatestDriver {
    param ($Driver)

    $osId = 135;
    $url = "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=$($Driver.FamilyId)&pfid=$($Driver.DriverId)&osID=$osId&languageCode=1033&beta=null&isWHQL=1&dltype=-1&dch=1&upCRD=null&qnf=0&ctk=null&sort1=1&numberOfResults=1";
    $downloadInfo = (curl.exe -s $url | ConvertFrom-Json).IDS[0].downloadInfo;
    return @{
        Version = [double]$downloadInfo.Version
        Url     = $downloadInfo.DownloadURL
    }
}

function Wait-Aria2Download {
    param ($Id, $Name)

    while ($true) {
        $status = (Get-DownloadStatus -Ids $Id)[$Id];
        if ($status.State -eq "Complete") {
            break;
        }

        if ($status.State -in "Error", "Removed") {
            throw ($status.Error ?? "The download of $Name was removed from aria2.");
        }

        $percent = $status.Total ? [int]($status.Done * 100 / $status.Total) : 0;
        $state = $status.State -eq "Paused" ? "Paused, resume it in AriaNg" : "$([Math]::Round($status.Speed / 1MB, 1)) MB/s";
        Write-Progress -Activity "Downloading $Name" -Status "$percent% - $state" -PercentComplete $percent;
        Start-Sleep -Seconds 1;
    }

    Write-Progress -Activity "Downloading $Name" -Completed;
}

function Save-Driver {
    param ($Url, $Folder, [switch]$Wait)

    $name = Split-Path $Url -Leaf;
    $path = Join-Path $Folder $name;
    if ((Test-Path -LiteralPath $path) -and -not (Test-Path -LiteralPath "$path.aria2")) {
        return $path;
    }

    if ($Downloader -eq "Aria2") {
        Import-Module "$PSScriptRoot\..\..\..\Downloaders\Managers\Aria2\Aria2.psm1";
        Start-DownloadManager | Out-Null;
        Write-Host "Sending the driver to aria2, saving to $path";
        $id = Add-Download -Item @{ Url = $Url; Headers = @{ "User-Agent" = $UserAgent }; Connections = 16; Directory = $Folder; FileName = $name };
        if ($Wait) {
            Wait-Aria2Download -Id $id -Name $name;
        }
    }
    else {
        Write-Host "Downloading the driver to $path using Invoke-WebRequest";
        Invoke-WebRequest $Url -OutFile $path -UserAgent $UserAgent;
    }

    return $path;
}

function Find-Update {
    $installed = Get-InstalledDriver;
    $driver = $installed.Driver ?? (Select-Driver);
    $latest = Get-LatestDriver -Driver $driver;
    return @{
        Title    = "$($driver.Key) $($latest.Version) (Installed: $($installed.Version))"
        Outdated = $installed.Version -lt $latest.Version
        Version  = $latest.Version
        Url      = $latest.Url
    }
}

function Install-Driver {
    param ($Update)

    $extractPath = "$env:TEMP\NvidiaDriver\$($Update.Version)";
    if (-not (Test-Path -LiteralPath "$extractPath\setup.exe")) {
        $path = Save-Driver -Url $Update.Url -Folder (New-Item -ItemType Directory -Force "$env:TEMP\NvidiaDriver").FullName -Wait;
        Write-Host "Extracting the driver to $extractPath, Please ensure 7zip is installed and added to Path";
        Start-Process 7z -ArgumentList @("x", """$path""", "-o""$extractPath""", "-y") -NoNewWindow -Wait;
    }

    Start-Process -FilePath "$extractPath\setup.exe" -ArgumentList "-passive -noreboot -noeula -nofinish -s -clean" -Wait;
}
#endregion

switch ($Action) {
    "Test" { return [bool](Get-Controller) }
    "Find" { return Find-Update }
    "Download" { return Save-Driver -Url $Update.Url -Folder $Folder }
    "Install" { Install-Driver -Update $Update }
}