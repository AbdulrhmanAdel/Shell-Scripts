[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$ExtractScriptPath = Resolve-Path -Path "$PSScriptRoot/../Media/Extract-Track.ps1";
$Subs = $Files  | ForEach-Object {
    return & $ExtractScriptPath -FirstSubtitle -Files $_;
}

& "$PSScriptRoot/Translate/Translate.ps1" -Files $Subs;
$Subs | ForEach-Object {
    Remove-Item -LiteralPath $_;
}
