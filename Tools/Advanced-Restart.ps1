# Docs: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/shutdown
$Type = Single-Options-Selector.ps1 -Options @("Bios", "Safe Mode") -Title "Please Select Process";
switch ($Type) {
    "Bios" {
        shutdown.exe /r /fw /t 0;
        break;
    }
    "Safe Mode" {
        shutdown.exe /r /o /t 0;
        break;
    }
}