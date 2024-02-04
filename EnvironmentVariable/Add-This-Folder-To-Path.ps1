$continue = Read-Host "Are you sure you want to continue?";

if ($continue) {
    $variable = $args[0];
    $path = [Environment]::GetEnvironmentVariable('path', [EnvironmentVariableTarget]::User);
    $path += ";$variable";
    [Environment]::SetEnvironmentVariable('Path', $path, [EnvironmentVariableTarget]::User);
    Write-Output "New Path Variable Is $path";
    Read-Host "PRESS ANY KEY TO EXIT."
}
