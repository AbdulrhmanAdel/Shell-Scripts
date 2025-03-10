& Run-AsAdmin.ps1;

# $extensionId = Read-Host "Please Enter ExtensionId";
$extensionId = "ljldjoinchpemdfjpmjhdfljmlmbicgm"
$scriptPath = ".\Tools-Communicator.ps1";
$JsonName = "Tools-Communicator.Json"
$name = "com.at_dev.tools"
@{
    name            = $name
    description     = "Icon Communicator native messaging host"
    path            = $scriptPath
    type            = "stdio"
    allowed_origins = @("chrome-extension://$extensionId/")
} | ConvertTo-Json -Depth 100 -Compress | `
    Out-File "$($PSScriptRoot)\$JsonName";

$key = "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\$name";
$value = "$($PSScriptRoot)\$JsonName";
reg add $key /ve /d $value /f;
& Force-ManuallyExit.ps1;

