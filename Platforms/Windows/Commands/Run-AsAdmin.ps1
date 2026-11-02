[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    $Arguments = @(),
    [switch]
    $UseSameArguments
)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Under the software updater, exiting would end the whole update run, so its shim reruns the updater elevated instead
    if ($env:APP_UPDATER_RUNNING -eq '1') {
        throw 'APP_UPDATER_NEEDS_ADMIN';
    }

    $path = (Get-PSCallStack | Select-Object -Skip 1 | Where-Object { $_.ScriptName } | Select-Object -First 1).ScriptName;
    $processArguments = @(
        "-File", """$path"""
    ) + @($Arguments | Where-Object { $_ -ne $null });

    Start-Process pwsh.exe -Verb RunAs -ArgumentList $processArguments;
    [Environment]::Exit(0);
}