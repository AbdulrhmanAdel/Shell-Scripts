param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string]$ExePath
)

if ($ExePath.EndsWith('.lnk')) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ExePath)
    $ExePath = $shortcut.TargetPath
}

Write-Host "Running script to toggle RunAsAdmin for $ExePath" -ForegroundColor Green;
$regPath = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers";
# $regData = Get-ItemProperty -Path $regPath -Name $ExePath -ErrorAction SilentlyContinue;
$regData = Get-ItemProperty -Path $regPath -Name $ExePath -ErrorAction SilentlyContinue;
$regValue = $regData.$($ExePath);
if (!$regData -OR !$regValue) {
    Write-Host "This File Has No Compatibility Settings Applied" -ForegroundColor Green;
    timeout.exe 5;
    Exit
}

Write-Host "Current Settings: $($regValue ?? 'No Settings')" -ForegroundColor Green;
$settingsFlags = @(
    @{
        Regex       = "~? ?RUNASADMIN";
        Description = "Run as administrator";
    }
);

$settingsFlags | ForEach-Object {
    $regValue = $regValue -replace $_.Regex, '';
}

Set-ItemProperty -Path $regPath -Name $ExePath -Value $regValue;
timeout 5;

