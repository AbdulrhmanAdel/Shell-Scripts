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
    $classPath = "HKEY_LOCAL_MACHINE\Software\Classes";
}

# Register the app itself so it shows up in the Explorer "Open with" list,
# independent of which ProgID currently owns each extension.
$appKey = "$classPath\Applications\$global:programName";
reg add "$appKey\shell\open\command" /d """$ProgramPath"" ""%1""" /f | Out-Null;

$Extensions | ForEach-Object {
    $extension = $_.StartsWith(".") ? $_ : ".$_";
    $base = $classPath;

    reg add "$appKey\SupportedTypes" /v $extension /d "" /f | Out-Null;

    $progId = "$global:programName$extension";
    reg add "$base\$extension" /d $progId /f | Out-Null;
    reg add "$base\$extension\OpenWithProgids" /v $progId /d "" /f | Out-Null;
    $key = "$base\$progId\shell\open\command";
    reg add $key /d """$ProgramPath"" ""%1""" /f | Out-Null;
}


