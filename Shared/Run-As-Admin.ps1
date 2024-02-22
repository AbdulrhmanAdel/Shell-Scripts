$runningFilePath = $PSCommandPath;

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process Powershell -Verb RunAs "-File $runningFilePath";
    exit;
}