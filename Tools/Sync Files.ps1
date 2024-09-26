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
enum SyncTarget {
    Watch    
    Programs
    ProgrammingPrograms
    PersonalProjects
    WorkProjects
    GameSaves
    ProgramsData
    Fortnite
    Quarn
    Cancel
}


$syncProgramPath = "D:\Programs\Tools\Free File Sync"
$syncProgram = "$syncProgramPath\FreeFileSync.exe";
$mirrorConfig = "$syncProgramPath\Configs\Mirror.ffs_gui";
$updateConfig = "$syncProgramPath\Configs\Update.ffs_gui";
$programmingProjectConfig = "$syncProgramPath\Configs\Programming Projects.ffs_gui";
$workProjectConfig = "$syncProgramPath\Configs\Work Projects.ffs_gui";
$personalProjectConfig = "$syncProgramPath\Configs\Personal Projects.ffs_gui";
$programmingProgramsConfig = "$syncProgramPath\Configs\Programming Programs.ffs_gui";

function Sync {
    $type = [SyncTarget]::$(& Single-Options-Selector.ps1 -Options ([SyncTarget].GetEnumNames()));
    if ($null -eq $type -or $type -eq [SyncTarget]::Cancel) {
        EXIT;
    }
    
    $command = ""
    switch ($type) {
        ([SyncTarget]::Watch) {
            $command += " ""$updateConfig""";
            $command += " -DirPair ""D:\Watch"" ""$($driveLetter):\Watch"""; 
            break;
        }
    
        ([SyncTarget]::Programs) {
            $command += " ""$mirrorConfig""";
            $command += " -DirPair ""D:\Programs"" ""$($driveLetter):\Programs""";  
            break;
        }
        ([SyncTarget]::ProgrammingPrograms) {
            $command += " ""$programmingProgramsConfig""";
            $command += " -DirPair ""D:\Programming\Programs"" ""$($driveLetter):\Programming\Programs"""; 
            break;
        }
        ([SyncTarget]::PersonalProjects) { 
            $command += " ""$personalProjectConfig""";
            $command += " -DirPair ""D:\Programming\Projects\Personal Projects"" ""$($driveLetter):\Programming\Projects\Personal Projects"""; 
            break;
        }
        ([SyncTarget]::WorkProjects) { 
            $command += " ""$workProjectConfig""";
            $command += " -DirPair ""D:\Programming\Projects\Work"" ""$($driveLetter):\Programming\Projects\Work"""; 
            break;
        }
        ([SyncTarget]::GameSaves) { 
            $command += " ""$programmingProjectConfig""";
            $command += " -DirPair ""D:\Personal\Game Saves"" ""$($driveLetter):\Personal\Game Saves""";
            break;
        }
        ([SyncTarget]::ProgramsData) {
            $command += " ""$mirrorConfig""";
            $command += " -DirPair ""D:\Programming\Programs\1- Programs Data"" ""$($driveLetter):\Programming\Programs\1- Programs Data""";
            break;
        }
        ([SyncTarget]::Fortnite) {
            $command += " ""$mirrorConfig""";
            $command += " -DirPair ""D:\Games\Fortnite"" ""$($driveLetter):\Games\Fortnite""";
            break;
        }
        ([SyncTarget]::Quarn) {
            $command += " ""$mirrorConfig""";
            $command += " -DirPair ""D:\Personal\Media\القرأن الكريم"" ""$($driveLetter):\Personal\Media\القرأن الكريم""";
            break;
        }
        Default {
            Sync
            return;
        }
    }

    Write-Host "SYNCING $type" -ForegroundColor Green;
    Start-Process $syncProgram $command;
    Sync
}

Sync;
