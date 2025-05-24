[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$Subs = $Files  | ForEach-Object {
    $ExtractScriptPath = Resolve-Path -Path "$PSScriptRoot/../Media/Extract-Track.ps1";
    return & $ExtractScriptPath -FirstSubtitle -Files $_;
}

& "$PSScriptRoot/Translate/Translate.ps1" -Files $Subs;
$Subs | ForEach-Object {
    Remove-Item -LiteralPath $_;
}
