[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Name,
    [Parameter(Mandatory = $true)]
    [string]
    $secret
)

$SecureString = ConvertTo-SecureString -String $secret -AsPlainText -Force;
Set-Secret -Name $Name -Vault ShellScriptVault -SecureStringSecret $SecureString;
