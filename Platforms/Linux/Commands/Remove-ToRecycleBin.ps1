[CmdletBinding()]
param (
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths,
    $Color = [System.ConsoleColor]::Red
)

$Paths | ForEach-Object {
    Write-Host "Moving $_ TO RycleBin" -ForegroundColor $Color;
    & gio trash -- $_;
}
