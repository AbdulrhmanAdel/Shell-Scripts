[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Text
)

$Regex = " \[Fitgirl Repack\]| - \[Dodi Repack\]|-PSA|-Pahe\.in|\[AniDL\]|\(Hi10\)_?";
return $Text -replace '_', ' ' -replace ' +', ' ' -replace $Regex, '';




