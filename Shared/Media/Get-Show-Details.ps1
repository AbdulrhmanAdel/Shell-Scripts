. Parse-Args.ps1 $args

$canHandle = (Test-Path -LiteralPath $path) `
    -and $path -match "(\.mkv|\.mp4|\.srt|\.ass|)$";
if (!$canHandle) {
    Throw "INVALID PATH $path";
    return;
}

$seriesRegex = "(?<Title>.*) *(S|Season) *(?<SeasonNumber>\d{1,2}) *(Episode|Ep|E|\d+X)(?<EpisodeNumber>\d+) *(?<Rest>.*)"; ;
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
function GetQuailty {
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
        $quality = GetQuailty -name $name;
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
    if ($name -match $seriesRegex) {
        $showName = $Matches["Title"].Trim();
        $details.Type = "Series"
        $details.Season = [Int32]::Parse( $Matches["SeasonNumber"]);
        $details.Episode = [Int32]::Parse( $Matches["EpisodeNumber"]);
    }
    elseif ($name -match $moviesRegex) {
        $showName = $Matches["Title"].Trim();
    }

    $showName ??= $name;
    $year = GetYear -name $showName;
    $showName = $showName -replace $yearRegex, ""
    $details.Year = $year;
    $details.Title = $showName.Trim();
    return $details;
}


$info = Get-Item -LiteralPath $path -ErrorAction Ignore;
$name = $info.Name -replace $info.Extension, "";
$details = GetSeriesOrMovieDetails -name $name;
$details["Info"] = $info;
$details["FileName"] = $name;
return $details;

