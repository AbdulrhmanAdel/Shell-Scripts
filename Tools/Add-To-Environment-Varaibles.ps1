$folderPath = $args[0].ToString().ToLower();
$path = [Environment]::GetEnvironmentVariable('path', [EnvironmentVariableTarget]::User);
$pathes = $path -split ";";
$alreadyExists = $pathes.Contains($folderPath);
if ($alreadyExists) {
    Write-Host "Path Already Exists" -ForegroundColor Red
    timeout.exe 5;
    Exit;
}
$pathes = $pathes | Where-Object { return Test-Path -LiteralPath $_ };
$pathes += "$folderPath";
$path = $pathes -join ";";
[Environment]::SetEnvironmentVariable('Path', $path, [EnvironmentVariableTarget]::User);
Write-Output "New Path Variable Is $path";
Read-Host "PRESS ANY KEY TO EXIT."