[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    $Arguments = @()
)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $callStack = Get-PSCallStack
    $path = $callStack[1].ScriptName
    $processArguments = @(
        "-File", """$path"""
    )

    Start-Process pwsh.exe -Verb RunAs -File "$path" -ArgumentList $Arguments;
    [Environment]::Exit(0);
}