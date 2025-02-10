[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ProgramPath,
    [Parameter()]
    [string[]]
    $Extensions
)

$Extensions | ForEach-Object {
    $extension = $_;
    $base = "HKEY_CURRENT_USER\Software\Classes";
    $title = "$($ProgramPath.Split("\")[-1])$extension";
    reg add "$base\$extension" /d $title /f | Out-Null;
    $key = "$base\$title\shell\open\command";
    reg add $key /d $title /f | Out-Null;
}


