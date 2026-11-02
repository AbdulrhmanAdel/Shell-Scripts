[CmdletBinding()]
param (
    [switch]
    $NoTimeout,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths
)

$configPath = Join-Path $HOME '.config/environment.d/999-user-paths.conf';
New-Item -ItemType Directory -Force (Split-Path $configPath) | Out-Null;
$saved = @((Test-Path -LiteralPath $configPath) ? (Get-Content -LiteralPath $configPath) : @());
$lines = @($Paths | ForEach-Object { "PATH=${_}:`${PATH}" } | Where-Object { $_ -notin $saved });

if ($lines.Count -eq 0) {
    Write-Host "No New Paths Provided" -ForegroundColor Red;
}
else {
    Write-Host "Adding New Paths, they apply after the next login" -ForegroundColor Green;
    $Paths | ForEach-Object { Write-Host $_ };
    Add-Content -LiteralPath $configPath -Value $lines;
}

$profilePath = Join-Path $HOME '.profile';
$sourceLine = "[ -f `"$configPath`" ] && . `"$configPath`"";
if (!(Test-Path -LiteralPath $profilePath) -or (Get-Content -LiteralPath $profilePath) -notcontains $sourceLine) {
    Add-Content -LiteralPath $profilePath -Value $sourceLine;
}

if (!$NoTimeout) {
    Timeout.ps1 10;
}
