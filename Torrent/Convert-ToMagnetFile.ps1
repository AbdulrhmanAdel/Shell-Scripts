[CmdletBinding()]
param (
    [Parameter(Mandatory = $True, Position = 0)]
    [ValidateScript({ Test-Path -Path $_ })]
    [string]
    $Path
)

$data = & "$PsScriptRoot\Helpers\BencodedFile.ps1" -FilePath $Path;
Write-Host "Data";

