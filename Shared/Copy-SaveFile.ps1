[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $SaveCheckPath,
    [Parameter(Mandatory)]
    [string]
    $Destination,
    [Parameter()]
    [string]
    $TargetName
)

if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -Path $Destination -ItemType Directory -ErrorAction Ignore | Out-Null
}

$files = @(Get-ChildItem -LiteralPath $SaveCheckPath -Exclude "*.ps1", "*.lnk", "*.txt");
if ($files.Length -gt 1) {
    $Options = $files | ForEach-Object { return @{
            Key   = $_.Name
            Value = $_ 
        }
    };
    $files = Multi-Options-Selector.ps1 `
        -Options $Options `
        -Title "PLEASE select correct saves" -Required 
}

if ($files.Length -eq 0) {
    Write-Host "No Save File Selected Or Found";
    Prompt-Exit.ps1;
}

$files | ForEach-Object {
    Write-Host "Creating symbolic link for: $($_.Name)";
    $fileInfo = $_;
    if (!$TargetName) {
        $TargetName = $fileInfo.Name;
    }

    $targetPath = "$Destination\$TargetName";
    if (Test-Path -LiteralPath $targetPath) {
        $Item = Get-Item -LiteralPath $targetPath;
        if ($Item.LinkType -eq "SymbolicLink") {
            return;
        }
        Remove-Item -LiteralPath $targetPath -Force -Recurse;
    }
    
    New-Item `
        -Path $targetPath `
        -Target $fileInfo.FullName `
        -ItemType SymbolicLink;
        
    $errors = $Error;
    if ($errors.Count -gt 0 -and $errors[0].Exception.Message -eq "Administrator privilege required for this operation.") {
        Write-Host "Missing Admin Priv"
        Run-AsAdmin.ps1 -Arguments @(
            "-SaveCheckPath"
            """$SaveCheckPath"""
            "-Destination"
            """$Destination"""
        );
        EXIT;
    }
}

Invoke-Item $Destination;
timeout.exe 5;