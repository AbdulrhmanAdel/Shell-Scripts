[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Text
)

$Regex = " \[Fitgirl Repack\]| - \[Dodi Repack\]|-PSA|-Pahe\.in|\[AniDL\]";
return $Text -replace '_', ' ' -replace ' +', ' ' -replace $Regex, '';




