[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$name,
    $type
)

$show = Imdb-GetShow.ps1 -Name $name -Type $type;
$res = Invoke-WebRequest "https://www.imdb.com/title/$($show.id)";
$content = $res.Content 
$content -match '"ratingValue": ?(?<Rate>\d+\.\d+)'
return $Matches["Rate"];
