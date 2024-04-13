if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe -Verb RunAs "-Command ""$($MyInvocation.Line)""";
    exit;
}

$cropPath = "D:\Education\Projects\MyProjects\Shell-Scripts\Media\Crop\Crop.ps1";
$command = "pwsh.exe -file ""$cropPath"" ""%1""";

function Register {
    param ([string]$extension)
    $scriptsName = "Scripts"
    if ($extension -ne "*") {
        $scriptsName = "Special Scripts"
    }

    $scriptPath = "HKEY_CLASSES_ROOT\SystemFileAssociations\$extension\Shell\$scriptsName";
    reg add $scriptPath  /v "MUIVerb" /d "Special Scripts" /t REG_SZ /f | Out-Null;
    reg add $scriptPath  /v "SubCommands" /t REG_SZ /f | Out-Null;

    $base = "$scriptPath\shell\000 Media";
    reg add "$base" /v "MUIVerb" /d "Media" /t REG_SZ /f | Out-Null;
    reg add "$base" /v "SubCommands" /t REG_SZ /f | Out-Null;
    reg add "$base\shell" /v "Icon" /t REG_SZ /f | Out-Null;
    reg add "$base\shell\Crop" /d "Crop" /t REG_SZ /f | Out-Null;
    reg add "$base\shell\Crop\Command" /d $command /t REG_SZ /f | Out-Null;
}


@(".mp3", ".m4a") | ForEach-Object {
    Register -extension $_;
}