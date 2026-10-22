[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Path,
    # Gets the downloaded file's path, returns $true / @{ Success = $true } when it installed
    [Parameter(Mandatory)]
    [scriptblock]$Handler
)

try {
    $result = @(& $Handler $Path)[-1];
}
catch {
    # Run-AsAdmin.ps1 under the software updater, its shim reruns the updater elevated
    if ("$_" -eq 'APP_UPDATER_NEEDS_ADMIN') {
        throw;
    }
    Write-Host "[ERROR] Custom installer failed: $_" -ForegroundColor Red;
    return @{
        Success = $false
    }
}

return @{
    Success = $result -is [hashtable] ? [bool]$result.Success : [bool]$result
}
