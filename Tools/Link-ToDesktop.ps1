[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
)

$desktop = [Environment]::GetFolderPath('Desktop');
if (!$desktop) {
    $desktop = Join-Path $HOME 'Desktop';
}

New-Item -ItemType Directory -Force $desktop | Out-Null;

foreach ($path in $Paths) {
    $source = (Get-Item -LiteralPath $path -Force).FullName;
    Create-Shortcut.ps1 -Target (Join-Path $desktop (Split-Path $source -Leaf)) -Source $source;
}
