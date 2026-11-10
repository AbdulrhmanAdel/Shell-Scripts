[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]$Path,
    [switch]$OnlyBasicInfo,
    [switch]$UseImdb
)

$canHandle = $path -match "(\.mkv|\.mp4|\.srt|\.ass|)$";
if (!$canHandle) {
    Throw "INVALID PATH $path";
    return;
}

$notYear = "(?!(?:(?:19|20)\d{2}|480|576|720|1080|2160)\b)";
$seriesRegexes = @(
    "^(?<Title>.*?)(?:^| )(?:S|Season) ?(?<Season>\d{1,2}) ?(?:E|Ep|Episode|X)? ?$notYear(?<Episode>\d{1,4})\b",
    "^(?<Title>.*?)(?:^| )(?<Season>\d{1,2})X(?<Episode>\d{2,3})\b",
    "^(?<Title>.*?)(?:^| )(?:E|Ep|Episode) ?$notYear(?<Episode>\d{1,4})\b",
    "^(?<Title>.*?)(?:^| )(?:S|Season) ?(?<Season>\d{1,2})\b"
);
$animeRegex = "^(?<Title>.+?) - $notYear(?<Episode>\d{1,4})(?: |\.|$)";
$groupedAnimeRegex = "^(?<Title>.+?) $notYear(?<Episode>\d{1,4})(?: |$)";
$titleEndRegex = "^(?:(?:19|20)\d{2}|\d{3,4}p|4k|bluray|bdrip|brrip|webrip|webdl|hdrip|dvdrip|hdtv|x264|x265|h264|h265|hevc|\d+bit|remux|repack)$";

function SplitTitleAndYear {
    param (
        [string]$Title
    )

    $words = @($Title -split " " | Where-Object { $_ });
    for ($i = 1; $i -lt $words.Count; $i++) {
        if ($words[$i] -match $titleEndRegex) {
            $year = $words[$i] -match "^(19|20)\d{2}$" ? $words[$i] : $null;
            return @{ Title = $words[0..($i - 1)] -join " "; Year = $year }
        }
    }

    return @{ Title = $words -join " "; Year = $null }
}

# Allowed special characters in NTFS filenames
$pattern = '!|#|\$|%|&|\(|\)|-|@|\^|_|{|}|~|\+|=|,|;|\.|\[|\]'
function NormalizeName() {
    param (
        [string]$Name
    )
    
    $normalizedName = $Name -replace "^\[.*?\]", "" `
        -replace $pattern, " " `
        -replace " +", " ";
    return $normalizedName.Trim();
}

# https://en.wikipedia.org/wiki/Pirated_movie_release_types
$qualitiesRegex = @(
    "WEB(-| )?(DL|HD)",
    "WEB(-| )?RIP",
    "Blu(-| )?ray|BD|BR(-| )?Rip",
    "HD(-| )?Rip",
    "DVD(-| )?Rip",
    "HD(-| )?TV",
    @{
        KEY   = "WEB"
        Value = "WEB(-| )?(DL|RIP)"
    },
    @{
        Key   = "HEVC"
        Value = "WEB(-| )?(DL|RIP).*HEVC"
    }
);
function GetQuality {
    param (
        $name
    )

    foreach ($quality in $qualitiesRegex) {
        $key = $quality;
        $value = $quality;
        if ($quality.Key) {
            $key = $quality.Key;
            $value = $quality.Value;
        }
        if ($name -match $key) {
            return  $value;
        }
    }

    return $null;
}

$keywords = @("Repack", "Internal", "DIRECTOR'?S?(\.| )?CUT");
function GetSeriesOrMovieDetails {
    param (
        $name
    )
    $rawName = $name.Trim();
    $name = NormalizeName -name $rawName;
    if (!$onlyBasicInfo) {
        $quality = GetQuality -name $name;
        $matchedKeywords = @($keywords | Where-Object { $name -match $_ }) ?? @();
        $ignoredVersions = @($keywords | Where-Object { $_ -notin $matchedKeywords });
    }
    
    $details = @{
        Type            = "Movie"
        Quality         = $quality
        IgnoredVersions = $ignoredVersions
        Keywords        = $matchedKeywords
    };

    $series = $null;
    foreach ($regex in $seriesRegexes) {
        if ($name -match $regex) { $series = $Matches; break }
    }
    if (!$series -and ($rawName -replace "^\[.*?\]\s*", "") -match $animeRegex) {
        $series = $Matches;
        $series["Title"] = NormalizeName -name $series["Title"];
    }
    if (!$series -and $rawName -match "^\[" -and $name -match $groupedAnimeRegex) {
        $series = $Matches;
    }

    $split = SplitTitleAndYear -Title ($series ? $series["Title"] : $name);
    if ($series) {
        $details.Type = "Series";
        $details.Season = $series["Season"] ? [Int32]::Parse($series["Season"]) : 1;
        $details.Episode = $series["Episode"] ? [Int32]::Parse($series["Episode"]) : $null;
    }

    if ($UseImdb) {
        $imdbInfo = & Imdb-GetShow.ps1 -Name $split.Title -Year $split.Year;
        $details.Type = $imdbInfo.Type;
        $details.ImdbInfo = $imdbInfo;
    }

    $details.Year = $split.Year;
    $details.Title = $split.Title ? $split.Title : $name;
    return $details;
}


if (Test-Path -LiteralPath $path) {
    $info = Get-Item -LiteralPath $path -ErrorAction Ignore;
    $name = [System.IO.Path]::GetFileNameWithoutExtension($info.Name);
    $details = GetSeriesOrMovieDetails -name $name;
    $details["Info"] = $info;
    $details["FileName"] = $name;
    return $details;
}

$details = GetSeriesOrMovieDetails -name $Path;
$details["Info"] = $null;
$details["FileName"] = $Path;
return $details;

