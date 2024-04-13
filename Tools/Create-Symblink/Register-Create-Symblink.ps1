if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe -Verb RunAs "-Command ""$($MyInvocation.Line)""";
    exit;
}

$cropPath = "D:\Education\Projects\MyProjects\Shell-Scripts\Tools\Create-Symblink\Create-Symblink.ps1";
$command = "pwsh.exe -file ""$cropPath"" ""%1""";
function Register {
    param ([string]$extension)
    $scriptsName = "Scripts"
    if ($extension -ne "*" -and $extension -ne "Directory") {
        $scriptsName = "Special Scripts"
    }

    $scriptPath = "HKEY_CLASSES_ROOT\$extension\Shell\$scriptsName";
    reg add $scriptPath  /v "MUIVerb" /d $scriptsName /t REG_SZ /f | Out-Null;
    reg add $scriptPath  /v "SubCommands" /t REG_SZ /f | Out-Null;

    $base = "$scriptPath\shell\999 Tools";
    reg add "$base" /v "MUIVerb" /d "Tools" /t REG_SZ /f | Out-Null;
    reg add "$base" /v "SubCommands" /t REG_SZ /f | Out-Null;
    reg add "$base\shell" /v "Icon" /t REG_SZ /f | Out-Null;
    reg add "$base\shell\Create Symblink" /d "Create Symblink" /t REG_SZ /f | Out-Null;
    reg add "$base\shell\Create Symblink\Command" /d $command /t REG_SZ /f | Out-Null;
}


@("*", "Directory") | ForEach-Object {
    Register -extension $_;
}