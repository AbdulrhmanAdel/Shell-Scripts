[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Name
)

return Get-Secret -Name $Name -Vault ShellScriptVault -AsPlainText;