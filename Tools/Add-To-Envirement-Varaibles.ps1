$variable = $args[0].ToString().ToLower();
$path = [Environment]::GetEnvironmentVariable('path', [EnvironmentVariableTarget]::User);
$alreadyExists = ($path -split ";").Contains($variable);
if ($alreadyExists) {
    Write-Host "Path Already Exists" -ForegroundColor Red
    timeout.exe 5;
    Exit;
}

$path += ";$variable";
[Environment]::SetEnvironmentVariable('Path', $path, [EnvironmentVariableTarget]::User);
Write-Output "New Path Variable Is $path";
Read-Host "PRESS ANY KEY TO EXIT."