[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path
)
$Script:HasError = $false;
$ParentPath = Split-Path -Path $Path;
Get-ChildItem -Path $Path | ForEach-Object {
    try {
        Move-Item -Path $_.FullName -Destination $ParentPath -Force;
    }
    catch {
        $Script:HasError = $true;
    }
}

if (!$Script:HasError) {
    if (-not (Get-ChildItem -LiteralPath $Path)) {
        Remove-Item -Path $Path -Force -Recurse;
    }
    return @{
        Success = $true
    }
}

return @{
    Success = $false
}



