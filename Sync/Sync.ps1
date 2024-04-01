$syncProgram = "D:\Programs\Tools\Free File Sync\FreeFileSync.exe";
$type = [int](Read-Host "
    1- Watch    
    2- Programs
    3- Education Programs
    4- Education Projects
");

$mirrorConfig = "D:\Programs\Tools\Free File Sync\Configs\Mirror.ffs_gui";
$updateConfig = "D:\Programs\Tools\Free File Sync\Configs\Update.ffs_gui"
$command = ""

switch ($type) {
    1 {
        $command += " ""$updateConfig""";
        $command += " -DirPair ""D:\Watch"" ""E:\Watch"""; 
    }
    2 {
        $command += " ""$mirrorConfig""";
        $command += " -DirPair ""D:\Programs"" ""E:\Programs""";  
    }
    3 {
        $command += " ""$mirrorConfig""";
        $command += " -DirPair ""D:\Education\Programs"" ""E:\Education\Programs"""; 
    }
    4 { 
        $command += " ""D:\Programs\Tools\Free File Sync\Configs\Education Projects.ffs_gui""";
        $command += " -DirPair ""D:\Education\Projects"" ""E:\Education\Projects"""; 
    }
    Default {
        exit
    }
}

Start-Process $syncProgram $command;