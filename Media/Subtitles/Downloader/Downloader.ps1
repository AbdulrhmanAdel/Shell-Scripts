$specialChars = "[-,|,_,*,#,\.,\],\[]";
$seriesRegex = "(?<Name>.*)(S|Season|S(?<SeasonNumber>\d+))(Episode|Ep|E|$specialChars|\[| |\dx)(?<EpisodeNumber>\d+)([-,|,_,*,#,\.]| |\]|v\d+)(?<ExtraInfo>.*)(?<Quality>(720|480|1080)P?)(?<Rest>.*)"; ;
$moviesRegex = "(?<Name>.*)(?<Year>\d\d\d\d)(?<ExtraInfo>.*)(?<Quality>(720|480|1080)P?)(?<Rest>.*)";


# https://en.wikipedia.org/wiki/Pirated_movie_release_types
$qualitiesRegex = @(
    "WEB(-| )?DL",
    "WEB(-| )?RIP",
    "Blu(-| )?ray|BD|BR(-| )?Rip",
    "HD(-| )Rip",
    "DVD(-| )Rip",
    "HDTV"
);
function GetQuailty {
    param (
        $name
    )

    foreach ($quality in $qualitiesRegex) {
        if ($name -match $quality) {
            return $quality;
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

$movies = $subs | Where-Object { $_.Details.Type -eq "M" };
$movies | Where-Object {
    $info = $_.Info;
    $details = $_.Details;
    & "$($PSScriptRoot)/Sites/Subsource.ps1" `
        -Type $details.Type `
        -Name $details.Name `
        -Quality $details.Quality `
        -SavePath $info.Directory.FullName `
        -RenameTo $_.Name `
        -ExtraInfo $details.ExtraInfo;
}


$series = $subs | Where-Object { $_.Details.Type -eq "S" };
if ($series.Length -eq 0) {
    timeout.exe 15;
    EXIT;
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
            -Type "S" `
            -Name $serieName `
            -Season $_ `
            -Episodes $season; 
    }
}


timeout.exe 30;