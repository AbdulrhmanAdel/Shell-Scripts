[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $Project,
    [Parameter(Mandatory)]
    [string]
    $TitleMatch
)

$data = curl "https://sourceforge.net/projects/$Project/rss"
[xml]$xml = $data;
$items = $xml.GetElementsByTagName('item');
$latest = $items | Where-Object {
    $itemTitle = $_.GetElementsByTagName('title').item(0)
    return $itemTitle.InnerText -match "$TitleMatch"
} | Select-Object -First 1
# $latest.link -match "hwi_(?<Version>\d+)\.zip" | Out-Null
$version = [float]::Parse($Matches['Version'].Insert(1, '.'))
return @{
    Version = $version
    Link    = "https://netcologne.dl.sourceforge.net/project/$Project/$TitleMatch/hwi_$($Matches['Version']).zip?viasf=1"
}
