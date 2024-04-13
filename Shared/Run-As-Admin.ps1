if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe -Verb RunAs "-Command ""$($MyInvocation.Line)""";
    exit;
}

$d = $MyInvocation;
Write-Host "$($args[0])"
Read-Host "Enter Data";