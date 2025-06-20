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

$seriesRegex = "(?<Title>.*) *(S|Season) *(?<SeasonNumber>\d{1,2}) *( |Episode|Ep|E|-|\d+X) *(?<EpisodeNumber>\d+) *(?<Rest>.*)";
$seriesRegexV2 = "(?<Title>.*)(?<EpisodeNumber>\d{1,3}) (720|480|1080)P?.*";
$moviesRegex = "(?<Title>.*)(?<Rest>(720|480|1080)P?.*)";
$yearRegex = [regex]::new("(?<YEAR>\d{4})(?=\D*$)")
function GetYear {
    param (
        $name
    )

    $result = $yearRegex.Match($name);

    return $result.Success `
        ? $result.ToString() `
        : $null
}

function GetShowVersion {
    param (
        $name,
        $Year
    )

    if ($name -match "$year(?<Version>.*)") {
        return $Matches["Version"]
    }

    return $null;
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
    $name = NormalizeName -name $name;
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



    $showName = $null;
    if ($name -match $seriesRegex -or $name -match $seriesRegexV2) {
        $showName = $Matches["Title"].Trim();
        $details.Type = "Series"
        $details.Season = $Matches["SeasonNumber"] ? [Int32]::Parse( $Matches["SeasonNumber"]) : $null;
        $details.Episode = $Matches["EpisodeNumber"] ? [Int32]::Parse( $Matches["EpisodeNumber"]) : $null;
    }
    elseif ($name -match $moviesRegex) {
        $showName = $Matches["Title"].Trim();
    }

    $imdbInfo = $null;
    if ($UseImdb) {
        $imdbInfo = & Imdb-GetShow.ps1 -Name $showName;
        $details.Type = $imdbInfo.Type;
        $details.ImdbInfo = $imdbInfo;
    }

    $showName ??= $name;
    $year = GetYear -name $showName;
    if ($year) {
        if (!$onlyBasicInfo) {
            $version = GetShowVersion -name $showName -year $year;
            if ($version) {
                $details['Keywords'] = $details['Keywords'] + $version.Trim();
            }
        }

        $showName = $showName -replace "$year.*", "";
    }

    $details.Year = $year;
    $details.Title = $showName.Trim();
    return $details;
}


if (Test-Path -LiteralPath $path) {
    $info = Get-Item -LiteralPath $path -ErrorAction Ignore;
    $name = $info.Name -replace $info.Extension, "";
    $details = GetSeriesOrMovieDetails -name $name;
    $details["Info"] = $info;
    $details["FileName"] = $name;
    return $details;
}

$details = GetSeriesOrMovieDetails -name $Path;
$details["Info"] = $null;
$details["FileName"] = $Path;
return $details;

