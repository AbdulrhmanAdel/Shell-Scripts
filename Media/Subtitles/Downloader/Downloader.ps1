$seriesRegex = "(?<Name>.*) *(S|Season) *(?<SeasonNumber>\d{1,2}) *(Episode|Ep|E|\d+X)(?<EpisodeNumber>\d+) *(?<Rest>.*)"; ;
$moviesRegex = "(?<Name>.*)(?<Rest>(720|480|1080)P?.*)";
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
$pattern = '!|#|\$|%|&|''|\(|\)|-|@|\^|_|`|{|}|~|\+|=|,|;|\.|\[|\]'
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

    $rest = $Matches["Rest"];
    $rest = $rest -replace "(720|480|1080)P?", " " -replace " +", "(\. | | - | )?";
    return $rest.Trim();
}


$versions = @("Repack", "Internal");
function GetSeriesOrMovieDetails {
    param (
        $name
    )
    $name = NormalizeName -name $name;

    $ignoredVersions = @($versions | Where-Object { $name -notcontains $_ })
    $isSeries = $name -match $seriesRegex;
    if ($isSeries) {
        $movieName = $Matches["Name"].Trim();
        $year = GetYear -name $movieName;
        return @{
            Type            = "S"
            Name            = $movieName.Trim()
            Year            = $year
            Season          = [Int32]::Parse( $Matches["SeasonNumber"])
            Episode         = [Int32]::Parse( $Matches["EpisodeNumber"])
            Quality         = GetQuailty -name $Matches["Rest"]
            IgnoredVersions = $ignoredVersions
        }
    }

    $isMovie = $name -match $moviesRegex;
    if ($isMovie) {
        $movieName = NormalizeName -name $Matches["Name"];
        $year = GetYear -name $movieName;
        return @{
            Type            = "M"
            Name            = $movieName.Trim()
            Year            = $year
            Quality         = GetQuailty -name $Matches["Rest"]
            IgnoredVersions = $ignoredVersions
        }
    }

    return $null;
}

function HandleMovies {
    param($subs)
    $movies = $subs | Where-Object { $_.Details.Type -eq "M" };
    $movies | Where-Object {
        $info = $_.Info;
        $details = $_.Details;
        & "$($PSScriptRoot)/Sites/Subsource.ps1" `
            -DownloadPath $downloadPath `
            -Type $details.Type `
            -Name $details.Name `
            -Quality $details.Quality `
            -SavePath $info.Directory.FullName `
            -RenameTo $_.Name `
            -Year $details.Year `
            -IgnoredVersions $details.IgnoredVersions;
    }
}

function HandleSeries {
    param (
        $subs
    )
    $series = $subs | Where-Object { $_.Details.Type -eq "S" };
    if ($series.Length -eq 0) {
        return;
    }
    $final = @{};
    function GroupSeries {
        param (
            $episode
        )
        $details = $episode.Details;
        $episodeInfo = [PSCustomObject]@{
            Episode         = $details.Episode
            Quality         = $details.Quality
            SavePath        = $episode.Info.Directory.FullName;
            RenameTo        = $episode.Name;
            Year            = $details.Year
            IgnoredVersions = $details.IgnoredVersions
        };

        $serie = $final[$details.Name];
        if ($serie) {
            $season = $serie[$details.Season] ?? @();
            $serie[$details.Season] = $season + $episodeInfo ;
            return;
        }

        $final[$details.Name] = @{
            $details.Season = @($episodeInfo)
        }
    }

    $series | ForEach-Object { GroupSeries -episode $_ };
    $final.Keys | ForEach-Object {
        $serieName = $_;
        $serie = $final[$_];
        $serie.Keys | ForEach-Object {
            $seasonEpisodes = $serie[$_] | Sort-Object -Property Episode;
            $episodeWithYear = $seasonEpisodes | Where-Object { !!$_.Year } | Select-Object -First  1;
            & "$($PSScriptRoot)/Sites/Subsource.ps1" `
                -DownloadPath $downloadPath `
                -Type "S" `
                -Name $serieName `
                -Season $_ `
                -Year $episodeWithYear.Year `
                -Episodes $seasonEpisodes; 
        }
    }
}


$files = @();
$args | ForEach-Object {
    $info = Get-Item -LiteralPath $_ -ErrorAction Ignore;
    if (!$info) {
        return;
    }

    if ($info -is [System.IO.FileInfo]) {
        if ($info.Extension -in @(".mkv", ".mp4")) {
            $files += $info;
        }
        return;
    }


    $childern = Get-ChildItem -LiteralPath $info.FullName -Recurse -Include *.mkv, *.mp4;
    $files += $childern;
}

$subs = $files | ForEach-Object {
    $info = $_;
    $name = $info.Name -replace $info.Extension, "";
    $details = GetSeriesOrMovieDetails -name $name;
    if (!$details) { return $null; }
   
    return @{
        Name    = $name
        Info    = $info
        Details = $details
    }
} | Where-Object {
    return $null -ne $_;
};


$downloadPath = "$($env:TEMP)/MyScripts/Subtitle-Downloader";
if (!(Test-Path -LiteralPath $downloadPath)) {
    New-Item -Path $downloadPath -ItemType Directory -Force;
}
HandleMovies -subs $subs;
HandleSeries -subs $subs;
Remove-Item  -LiteralPath $downloadPath -Force -Recurse;
timeout.exe 30;