& Run-As-Admin.ps1;

$extensionId = Read-Host "Please Enter ExtensionId";
$scriptPath = "$($PSScriptRoot)\Icon-Communicator.ps1";
$name = "com.at_dev.icon_downloader"
@{
    name            = $name
    description     = "Icon Communicator native messaging host"
    path            = $scriptPath
    type            = "stdio"
    allowed_origins = @("chrome-extension://$extensionId/")
} | ConvertTo-Json -Depth 100 -Compress | `
    Out-File "$($PSScriptRoot)\Icon-Communicator.Json";

$key = "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\$name";
$value = "$($PSScriptRoot)\Icon-Communicator.Json";
reg add $key /ve /d $value /f;
& Force-Manually-Exit.ps1;

