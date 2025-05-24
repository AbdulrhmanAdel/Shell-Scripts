[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    $Arguments = @(),
    [switch]
    $UseSameArguments
)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $callStack = Get-PSCallStack
    $path = $callStack[1].ScriptName
    $processArguments = @(
        "-File", """$path"""
    ) + $Arguments;

    Start-Process pwsh.exe -Verb RunAs -ArgumentList $processArguments;
    [Environment]::Exit(0);
}