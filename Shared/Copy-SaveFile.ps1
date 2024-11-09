[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $SaveCheckPath,
    [Parameter(Mandatory)]
    [string]
    $Destiniation
)
Write-Host  "F" + $MyInvocation.MyCommand.Path;
$files = Get-ChildItem -LiteralPath $SaveCheckPath -Exclude "*.ps1";
$fileInfo = $null;
if ($files.Length -gt 1) {
    $fileInfo = Single-Options-Selector.ps1 `
        -Options (
        $files | ForEach-Object { return @{
                Key   = $_.Name
                Value = $_ 
            }
        }
    ) -Title "There is more than one possible save, PLEASE select correct one" -MustSelectOne 
}
else {
    $fileInfo = $files[0];
}

if (!$fileInfo) {
    Write-Host "No Save File Selected Or Found";
    timeout.exe 15;
}

Write-Host "Copying Save $($fileInfo.Name)" -ForegroundColor Cyan
$des = "$Destiniation\$($fileInfo.Name)";
if (Test-Path -LiteralPath $des) {
    Remove-Item -LiteralPath $des -Force -Recurse;
}

New-Item `
    -Path $des `
    -Target $fileInfo.FullName `
    -ItemType SymbolicLink;

timeout.exe 15;