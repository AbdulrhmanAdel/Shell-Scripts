[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Target,
    [Parameter(Mandatory)]
    [string]$Source
)

if (!$Target -or !$Source) {
    Write-Error -Message "Invalid soruce: $soruce -or target: $Target"
    Exit;
}

if ((Test-Path -LiteralPath $Target) -and $force) {
    Remove-Item -LiteralPath $Target -Force;
}

$shell = New-Object -comObject WScript.Shell
$shortcut = $shell.CreateShortcut($Target)
$shortcut.TargetPath = $Source;
$shortcut.Save();