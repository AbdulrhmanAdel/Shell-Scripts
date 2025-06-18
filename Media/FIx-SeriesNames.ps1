[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$infos = $Files | ForEach-Object {
    $name = Split-Path -Leaf -Path $_;
    return Get-ShowDetails.ps1 -Path $name -OnlyBasicInfo;
}

$Names = $infos | Group-Object -Property $Title;
Write-Host $Names.Keys;
$newName = Single-Options-Selector.ps1 -Options $Names -MustSelectOne;
Write-Host $newName;