$syncProgram = "D:\Programs\Tools\Free File Sync\FreeFileSync.exe";

Write-Host "GETTING DRIVE LETTER..." -ForegroundColor Green
$disk = Get-Disk -FriendlyName "WD My Passport 2626"
$part = Get-Partition -DiskNumber $disk.DiskNumber;
$driveLetter = $part.DriveLetter;
Write-Host "DRIVE LETTER RETRIEVED: $driveLetter" -ForegroundColor Green
function Sync {
    $type = [int](Read-Host "
    1- Watch    
    2- Programs
    3- Programming Programs
    4- Programming Projects
    5- Game Saves
    6- Programs Data
    7- Fortnite
");

    $mirrorConfig = "D:\Programs\Tools\Free File Sync\Configs\Mirror.ffs_gui";
    $updateConfig = "D:\Programs\Tools\Free File Sync\Configs\Update.ffs_gui"
    $command = ""

    switch ($type) {
        1 {
            $command += " ""$updateConfig""";
            $command += " -DirPair ""D:\Watch"" ""$($driveLetter):\Watch"""; 
            break;
        }
        2 {
            $command += " ""$mirrorConfig""";
            $command += " -DirPair ""D:\Programs"" ""$($driveLetter):\Programs""";  
            break;
        }
        3 {
            $command += " ""D:\Programs\Tools\Free File Sync\Configs\Programming Programs.ffs_gui""";
            $command += " -DirPair ""D:\Programming\Programs"" ""$($driveLetter):\Programming\Programs"""; 
            break;
        }
        4 { 
            $command += " ""D:\Programs\Tools\Free File Sync\Configs\Programming Projects.ffs_gui""";
            $command += " -DirPair ""D:\Programming\Projects"" ""$($driveLetter):\Programming\Projects"""; 
            break;
        }
        5 { 
            $command += " ""D:\Programs\Tools\Free File Sync\Configs\Programming Projects.ffs_gui""";
            $command += " -DirPair ""D:\Personal\Game Saves"" ""$($driveLetter):\Personal\Game Saves""";
            break;
        }
        6 {
            $command += " ""$mirrorConfig""";
            $command += " -DirPair ""D:\Programming\Programs\1- Programs Data"" ""$($driveLetter):\Programming\Programs\1- Programs Data""";
            break;
        }
        7 {
            $command += " ""$mirrorConfig""";
            $command += " -DirPair ""D:\Games\Fortnite"" ""$($driveLetter):\Games\Fortnite""";
            break;
        }
        Default {
            Sync
            return;
        }
    }

    Start-Process $syncProgram $command;
    Sync
}

Sync;
