[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    $Arguments = @(),
    [switch]
    $UseSameArguments
)

if ([Environment]::IsPrivilegedProcess) {
    return;
}

$path = (Get-PSCallStack | Select-Object -Skip 1 | Where-Object { $_.ScriptName } | Select-Object -First 1).ScriptName;
$processArguments = @($Arguments | Where-Object { $null -ne $_ } | ForEach-Object { "$_".Trim('"') });
& sudo env "PATH=$env:PATH" "PSModulePath=$env:PSModulePath" (Get-Process -Id $PID).Path -File $path @processArguments;
[Environment]::Exit($LASTEXITCODE);
