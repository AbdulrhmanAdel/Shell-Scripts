Write-Host "GETTING DRIVE LETTER..." -ForegroundColor Green
$disk = Get-Disk -FriendlyName "WD My Passport 2626" -ErrorAction Ignore
$part = Get-Partition -DiskNumber $disk.DiskNumber -ErrorAction Ignore;
$driveLetter = $part.DriveLetter;
if (!$driveLetter) {
    Write-Host "CAN'T RETRIEVED DRIVE LETTER" -ForegroundColor Red
    timeout 5;
    EXIT;
}

Write-Host "DRIVE LETTER RETRIEVED: $driveLetter" -ForegroundColor Green
$syncProgramPath = "D:\Programs\Tools\Free File Sync"
$mirrorConfig = "Mirror.ffs_gui";
$updateConfig = "Update.ffs_gui";
$programmingProjectConfig = "Programming Projects.ffs_gui";
$workProjectConfig = "Work Projects.ffs_gui";
$personalProjectConfig = "Personal Projects.ffs_gui";
$programmingProgramsConfig = "Programming Programs.ffs_gui";
$configs = @(
    @{
        Key    = "Programs"
        Config = $mirrorConfig
        Source = "D:\Programs"
        Target = "$($driveLetter):\Programs"
    }
    @{
        Key    = "Games' Saves"
        Config = $mirrorConfig
        Source = "D:\Personal\Game Saves"
        Target = "$($driveLetter):\Personal\Game Saves"
    }
    @{
        Key    = "Quran"
        Config = $mirrorConfig
        Source = "D:\Personal\Media\القرأن الكريم"
        Target = "$($driveLetter):\Personal\Media\القرأن الكريم"
    }
    @{
        Key    = "Fortnite"
        Config = $mirrorConfig
        Source = "E:\Games\Fortnite"
        Target = "$($driveLetter):\Games\Fortnite"
    }
    @{
        Key    = "Personal Projects"
        Config = $personalProjectConfig
        Source = "D:\Programming\Projects\Personal Projects"
        Target = "$($driveLetter):\Programming\Projects\Personal Projects"
    }
    @{
        Key    = "Work Projects"
        Config = $workProjectConfig
        Source = "D:\Programming\Projects\Work"
        Target = "$($driveLetter):\Programming\Projects\Work"
    }
    @{
        Key    = "Programing Data"
        Config = $mirrorConfig
        Source = "D:\Programming\Programs\1- Programs Data"
        Target = "$($driveLetter):\Programming\Programs\1- Programs Data"
    }
    @{
        Key    = "Programing Program"
        Config = $programmingProgramsConfig
        Source = "D:\Programming\Programs"
        Target = "$($driveLetter):\Programming\Programs"
    }
)

function SyncV2 {
    $config = Single-Options-Selector.ps1 -Options $configs;
    if ($null -eq $config) {
        EXIT;
    }

    $command = " ""$syncProgramPath\Configs\$($config.Config)""";
    $command += " -DirPair ""$($config.Source)"" ""$($config.Target)""";
    Write-Host "SYNCING $($config.Key)" -ForegroundColor Green;
    Start-Process "$syncProgramPath\FreeFileSync.exe" $command;    
}

while ($true) {
    SyncV2;
}