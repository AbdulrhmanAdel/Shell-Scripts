param(
    [Parameter(ValueFromRemainingArguments = $true)]
    # [ValidateScript({
    #         if (-not (Test-Path $_ -PathType Leaf)) {
    #             throw "File not found: $_"
    #         }
    #         if (($_.ToLower() -notlike '*.exe')) {
    #             throw "The specified path is not an .exe file: $_"
    #         }
    #         return $true
    #     })]]
    [string]$ExePath
)

Write-Host "Running script to toggle RunAsAdmin for $ExePath" -ForegroundColor Green;
$regPath = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers";
# $regData = Get-ItemProperty -Path $regPath -Name $ExePath -ErrorAction SilentlyContinue;
$regData = Get-ItemProperty -Path $regPath -Name $ExePath -ErrorAction SilentlyContinue;
if (!$regData) {
    Write-Host "This File Has No Compatibility Settings Applied" -ForegroundColor Green;
    timeout.exe 5;
    Exit
}

$AdminFlag = "~ RUNASADMIN";
$regValue = $regData.$($ExePath);
Write-Host "Current Settings: $($regValue ?? 'No Settings')" -ForegroundColor Green;
if ($regValue) {
    $regValue = ($regValue -replace [regex]::Escape($AdminFlag), '').Trim()
    Set-ItemProperty -Path $regPath -Name $ExePath -Value $regValue;
}

timeout 5;

