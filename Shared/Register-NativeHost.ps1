[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$ExtensionId,
    [Parameter(Mandatory = $true)][string]$ScriptPath,
    [Parameter(Mandatory = $true)][string]$JsonPath,
    [Parameter()][string]$Description = "Native Host for $ExtensionId"
)

Run-AsAdmin.ps1 -Arguments @(
    "-Name", """$Name""",
    "-ExtensionId", """$ExtensionId""",
    "-ScriptPath", """$ScriptPath""",
    "-JsonPath", """$JsonPath""",
    "-Description", """$Description"""
);

@{
    name            = $Name
    description     = $Description
    path            = $ScriptPath
    type            = "stdio"
    allowed_origins = @("chrome-extension://$ExtensionId/")
} | ConvertTo-Json -Depth 100 -Compress | `
    Out-File $jsonPath;

$key = "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\$Name";
$value = $jsonPath;
reg add $key /ve /d $value /f;
timeout 15;

