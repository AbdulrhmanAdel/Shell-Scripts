[CmdletBinding()]
param (

    [Parameter(ValueFromRemainingArguments = $true)]
    [switch]
    $NoTimeout,
    [string[]]
    $Paths
)
$path = [Environment]::GetEnvironmentVariable('path', [EnvironmentVariableTarget]::User);
$savedPaths = $path -split ";";
$newPaths = $Paths | Where-Object { !$savedPaths.Contains($_); };

if ($newPaths.Count -eq 0) {
    Write-Host "No New Paths Provided" -ForegroundColor Red;
    timeout.exe 5;
    Exit;
}

Write-Host "Adding New Paths to User Environment Variable" -ForegroundColor Green;
$newPaths | ForEach-Object { Write-Host $_ };
$finalPaths = ($savedPaths + $newPaths) -join ";";
[Environment]::SetEnvironmentVariable('Path', $finalPaths, [EnvironmentVariableTarget]::User);

if (-not $NoTimeout) {
    Exit;
}
timeout.exe 10;