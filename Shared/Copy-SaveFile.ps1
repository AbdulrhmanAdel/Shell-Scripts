[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $SaveCheckPath,
    [Parameter(Mandatory)]
    [string]
    $Destination
)

if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -Path $Destination -ItemType Directory -ErrorAction Ignore | Out-Null
}

$files = Get-ChildItem -LiteralPath $SaveCheckPath -Exclude "*.ps1", "*.lnk";
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
$targetPath = "$Destination\$($fileInfo.Name)";
if (Test-Path -LiteralPath $targetPath) {
    Remove-Item -LiteralPath $targetPath -Force -Recurse;
}

New-Item `
    -Path $targetPath `
    -Target $fileInfo.FullName `
    -ItemType SymbolicLink;

if (Prompt.ps1 -Message "Open Linked Folder") {
    explorer.exe $Destination; 
}

timeout.exe 15;