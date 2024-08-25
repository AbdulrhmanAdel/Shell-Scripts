$specialChars = "[-,|,_,*,#,\.,\],\[]";
$seriesRegex = "(?<Name>.*)(S|Season|S(?<SeasonNumber>\d+))(Episode|Ep|E|$specialChars|\[| |\dx)(?<EpisodeNumber>\d+)([-,|,_,*,#,\.]| |\]|v\d+)(?<ExtraInfo>.*)(?<Quality>(720|480|1080)P?)(?<Rest>.*)"; ;
$moviesRegex = "(?<Name>.*)(?<Year>\d\d\d\d)(?<ExtraInfo>.*)(?<Quality>(720|480|1080)P?)(?<Rest>.*)";
# https://en.wikipedia.org/wiki/Pirated_movie_release_types
$qualitiesRegex = @(
    "WEB(-| )?(DL|HD)",
    "WEB(-| )?RIP",
    "Blu(-| )?ray|BD|BR(-| )?Rip",
    "HD(-| )Rip",
    "DVD(-| )Rip",
    "HDTV",
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
    if ($Matches["Quality"]) {
        $rest = "(720|480|1080)P $rest"
    }

    return $rest.Trim() -replace " +", "(\.| |-|)?"
}

function GetSeriesOrMovieDetails {
    param (
        $name
    )
    $name = $name -replace "\.|-|_|\(|\)", " ";
    $isSeries = $name -match $seriesRegex;

    if ($isSeries) {
        return @{
            Type      = "S"
            Name      = $Matches["Name"].Trim()
            Season    = [Int32]::Parse( $Matches["SeasonNumber"].Trim())
            Episode   = [Int32]::Parse( $Matches["EpisodeNumber"].Trim())
            Quality   = GetQuailty -name $Matches["Rest"]
            ExtraInfo = $Matches["ExtraInfo"].Trim()
        }
    }

    $isMovie = $name -match $moviesRegex;
    if ($isMovie) {
        return @{
            Type      = "M"
            Name      = $Matches["Name"].Trim()
            Quality   = GetQuailty -name $Matches["Rest"]
            ExtraInfo = $Matches["ExtraInfo"].Trim()
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
            -ExtraInfo $details.ExtraInfo;
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
        $episodeInfo = @{
            Episode   = $details.Episode
            Quality   = $details.Quality
            SavePath  = $episode.Info.Directory.FullName;
            RenameTo  = $episode.Name;
            ExtraInfo = $details.ExtraInfo;
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
            $season = $serie[$_];
            & "$($PSScriptRoot)/Sites/Subsource.ps1" `
                -DownloadPath $downloadPath `
                -Type "S" `
                -Name $serieName `
                -Season $_ `
                -Episodes $season; 
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