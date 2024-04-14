$syncProgram = "D:\Programs\Tools\Free File Sync\FreeFileSync.exe";
function Sync {
    $type = [int](Read-Host "
    1- Watch    
    2- Programs
    3- Programming Programs
    4- Programming Projects
    5- Game Saves
");

    $mirrorConfig = "D:\Programs\Tools\Free File Sync\Configs\Mirror.ffs_gui";
    $updateConfig = "D:\Programs\Tools\Free File Sync\Configs\Update.ffs_gui"
    $command = ""

    switch ($type) {
        1 {
            $command += " ""$updateConfig""";
            $command += " -DirPair ""D:\Watch"" ""E:\Watch"""; 
            break;
        }
        2 {
            $command += " ""$mirrorConfig""";
            $command += " -DirPair ""D:\Programs"" ""E:\Programs""";  
            break;
        }
        3 {
            $command += " ""D:\Programs\Tools\Free File Sync\Configs\Programming Programs.ffs_gui""";
            $command += " -DirPair ""D:\Programming\Programs"" ""E:\Programming\Programs"""; 
            break;
        }
        4 { 
            $command += " ""D:\Programs\Tools\Free File Sync\Configs\Programming Projects.ffs_gui""";
            $command += " -DirPair ""D:\Programming\Projects"" ""E:\Programming\Projects"""; 
            break;
        }
        5 { 
            $command += " ""D:\Programs\Tools\Free File Sync\Configs\Programming Projects.ffs_gui""";
            $command += " -DirPair ""D:\Personal\Game Saves"" ""E:\Personal\Game Saves""";
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
