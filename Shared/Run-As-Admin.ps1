. Parse-Args.ps1 $args;
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $callStack = Get-PSCallStack
    $path = $callStack[1].ScriptName
    $arguments = @(
        "-File", """$path"""
    )

    $arguments += $args;
    Start-Process pwsh.exe -Verb RunAs -ArgumentList $arguments;
    # if (!$noExit) {
    [Environment]::Exit(0);
    # }
}
