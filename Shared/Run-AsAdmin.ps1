[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    $Arguments = @(),
    [switch]
    $UseSameArguments
)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $path = (Get-PSCallStack | Select-Object -Skip 1 | Where-Object { $_.ScriptName } | Select-Object -First 1).ScriptName;
    $processArguments = @(
        "-File", """$path"""
    ) + @($Arguments | Where-Object { $_ -ne $null });

    Start-Process pwsh.exe -Verb RunAs -ArgumentList $processArguments;
    [Environment]::Exit(0);
}