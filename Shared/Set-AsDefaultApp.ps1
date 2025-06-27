[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ProgramPath,
    [Parameter()]
    [string[]]
    $Extensions,
    [Parameter()]
    [switch]
    $Machine
)

$global:programName = $ProgramPath;
if (Test-Path -LiteralPath $ProgramPath ) {
    $global:programName = Split-Path -Path $ProgramPath -Leaf
}

$classPath = "HKEY_CURRENT_USER\Software\Classes";
if ($Machine) {
    $classPath = "HKEY_CURRENT_MACHINE\Software\Classes";
}

$Extensions | ForEach-Object {
    $extension = $_;
    $base = $classPath;
    reg add "$base\$extension" /d "$global:programName$extension" /f | Out-Null;
    $key = "$base\$global:programName$extension\shell\open\command";
    reg add $key /d """$ProgramPath"" ""%1""" /f | Out-Null;
}


