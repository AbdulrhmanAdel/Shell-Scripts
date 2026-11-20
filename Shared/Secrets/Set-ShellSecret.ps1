[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Name,
    [Parameter(Mandatory = $true)]
    [string]
    $secret
)

$SecureString = [System.Net.NetworkCredential]::new("", $secret).SecurePassword;
Set-Secret -Name $Name -Vault ShellScriptVault -SecureStringSecret $SecureString;
