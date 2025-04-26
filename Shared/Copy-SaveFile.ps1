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

$files = @(Get-ChildItem -LiteralPath $SaveCheckPath -Exclude "*.ps1", "*.lnk");
if ($files.Length -gt 1) {
    $Options = $files | ForEach-Object { return @{
            Key   = $_.Name
            Value = $_ 
        }
    };
    $files = Multi-Options-Selector.ps1 `
        -Options $Options `
        -Title "PLEASE select correct saves" -MustSelectOne 
}

if ($files.Length -eq 0) {
    Write-Host "No Save File Selected Or Found";
    timeout.exe 15;
}

$files | ForEach-Object {
    $fileInfo = $_;
    Write-Host "Copying Save $($fileInfo.Name)" -ForegroundColor Cyan
    $targetPath = "$Destination\$($fileInfo.Name)";
    if (Test-Path -LiteralPath $targetPath) {
        Remove-Item -LiteralPath $targetPath -Force -Recurse;
    }
    
    New-Item `
        -Path $targetPath `
        -Target $fileInfo.FullName `
        -ItemType SymbolicLink;
}

Invoke-Item $Destination;
timeout.exe 15;