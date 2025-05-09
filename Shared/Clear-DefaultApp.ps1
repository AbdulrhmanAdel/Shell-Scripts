[CmdletBinding()]
param (
    [Parameter()]
    [string[]]
    $Extensions
)

$classPath = "HKEY_CURRENT_USER\Software\Classes";
$Extensions | ForEach-Object {
    $extension = $_;
    $path = "Registry::$classPath\$extension"
    if (-not (Test-Path -Path $path)) {
        Write-Host "No Default App Set For $extension" -ForegroundColor Green;
        return;
    }
    $default = (Get-ItemProperty -Path $path)."(default)";
    reg delete "$classPath\$default" /f | Out-Null;
    reg delete "$classPath\$extension" /f | Out-Null;
    # reg delete "HKEY_CURRENT_USER\Software\Classes\$extension" /f | Out-Null
}