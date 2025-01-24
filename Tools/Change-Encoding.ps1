[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]
    $Path
)


$Encoding = Get-FileEncoding.ps1 -File  $Path;
$script:Content = Get-Content -LiteralPath $Path -Encoding $Encoding;
Set-Content -Value $script:Content -LiteralPath "D:\input.srt" -Encoding "UTF8";
