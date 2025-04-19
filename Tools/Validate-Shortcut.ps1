[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Shortcuts
)

$WshShell = New-Object -ComObject WScript.Shell
$Groups = $Shortcuts | ForEach-Object {
    $shortcut = $WshShell.CreateShortcut($_);
    return @{
        Valid    = Test-Path -LiteralPath $shortcut.TargetPath;
        FileName = Split-Path $_ -Leaf;
    }
} | Group-Object -Property Valid;

$Groups | ForEach-Object {
    $isValid = $_.Name -eq "True";
    $Color = $isValid ? [System.ConsoleColor]::Green : [System.ConsoleColor]::Red;
    Write-Host "$($isValid ? 'Valid' : 'Invalid') Shortcuts " -ForegroundColor $Color;

    $_.Group | ForEach-Object {
        Write-Host $_.FileName -ForegroundColor $Color;
    }

    Write-Host "" -ForegroundColor White;
    Write-Host "=============================" -ForegroundColor White;
    Write-Host "" -ForegroundColor White;
}

