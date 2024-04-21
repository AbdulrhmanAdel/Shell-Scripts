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
$updateConfig = "$syncProgramPath\Configs\Update.ffs_gui"
function Sync {
    $type = & Options-Selector.ps1 ([SyncTarget].GetEnumNames());
    
    if ($type) {
        $type = [SyncTarget]::$($type);
    }
    
    $command = ""
    [SyncTarget]::Watch
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
        ([SyncTarget]::PersonalProjects) { 
            $command += " ""$mirrorConfig""";
            $command += " -DirPair ""D:\Programming\Projects\Personal Projects"" ""$($driveLetter):\Programming\Projects\Personal Projects"""; 
            break;
        }
        ([SyncTarget]::ProgrammingPrograms) {
            $command += " ""$mirrorConfig""";
            $command += " -DirPair ""D:\Programming\Programs"" ""$($driveLetter):\Programming\Programs"""; 
            break;
        }
        ([SyncTarget]::WorkProjects) { 
            $command += " ""D:\Programs\Tools\Free File Sync\Configs\Programming Projects.ffs_gui""";
            $command += " -DirPair ""D:\Programming\Projects\Work"" ""$($driveLetter):\Programming\Projects\Work"""; 
            break;
        }
        ([SyncTarget]::GameSaves) { 
            $command += " ""D:\Programs\Tools\Free File Sync\Configs\Programming Projects.ffs_gui""";
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
        { ([SyncTarget]::Cancel) -or $null } {
            Exit;
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
