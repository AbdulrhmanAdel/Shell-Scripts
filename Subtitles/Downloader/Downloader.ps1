[CmdletBinding()]
param (
    [Parameter(HelpMessage = "Force download even if subtitle exists (Soft or Separate File)")]
    [switch]
    $Force,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths
)


$handler = "Subdl"

function HandleMovies { 
    param($subs)
    $movies = $subs | Where-Object { $_.Details.Type -eq "Movie" };
    $movies | Where-Object {
        $info = $_.Info;
        $details = $_.Details;
        $imdb = $imdbCache[$details.Title];
        Write-Host $details;    
        $Show = @{
            Title    = $details.Title
            Type     = $details.Type
            Year     = $details.Year
            Season   = $_ 
            Episodes = $seasonEpisodes
            ImdbId   = $imdb.Id
        }
        & "$($PSScriptRoot)/Sites/$handler.ps1" `
            -Show $Show `
            -Quality $details.Quality `
            -SavePath $info.Directory.FullName `
            -RenameTo $_.Name `
            -IgnoredVersions $details.IgnoredVersions `
            -Keywords $details.Keywords;
    }
}

function HandleSeries {
    param (
        $subs
    )
    $series = $subs | Where-Object { $_.Details.Type -eq "Series" };
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
            Keywords        = $details.Keywords
        };

        $show = $final[$details.Title];
        if ($show) {
            $season = $show[$details.Season] ?? @();
            $show[$details.Season] = $season + $episodeInfo ;
            return;
        }

        $final[$details.Title] = @{
            $details['Season'] = @($episodeInfo)
            ShowId             = $episode.Imdb.Id
        }
    }

    $series | ForEach-Object { GroupSeries -episode $_ };
    $final.Keys | ForEach-Object {
        $showName = $_;
        $show = $final[$_];
        $show.Keys | Where-Object { $_ -ne "ShowId" } | ForEach-Object {
            $seasonEpisodes = $show[$_] | Sort-Object -Property Episode;
            $episodeWithYear = $seasonEpisodes | Where-Object { !!$_.Year } | Select-Object -First  1;
            $Show = @{
                Title    = $showName
                Type     = "Series"
                Year     = $episodeWithYear.Year
                Season   = $_ 
                Episodes = $seasonEpisodes
                ImdbId   = $show.ShowId
            }
            & "$($PSScriptRoot)/Sites/$handler.ps1" -Show $Show;
        }
    }
}

$files = @();
$Paths | ForEach-Object {
    $info = Get-Item -LiteralPath $_ -ErrorAction Ignore;
    if (!$info) {
        return;
    }

    if ($info -is [System.IO.FileInfo]) {
        if ($info.Extension -in @(".mkv", ".mp4")) {
            $hasArabicSoftSub = Has-SoftSubbedArabic.ps1 -Path $_;
            if ($hasArabicSoftSub -and !$Force) {
                Write-Host "Skipping $($info.Name) as it has arabic soft sub." -ForegroundColor DarkCyan;
                return;
            }
            $files += $info;
        }
        return;
    }


    $childern = Get-ChildItem -LiteralPath $info.FullName -Recurse -Include *.mkv, *.mp4;
    $files += $childern;
}

$imdbCache = @{};
$subs = $files | ForEach-Object {
    $details = & Get-ShowDetails.ps1 -Path $_.FullName;
    if (!$imdbCache.Contains($details.Title)) {
        $imdbCache[$details.Title] = Imdb-GetShow.ps1 -name $details.Title -FileInfo $_;
    }
    if (!$details) { return $null; }
    $imdb = $imdbCache[$details.Title];
    $details.Type = $imdb.type ? $imdb.type : $details.Type;
    $info = $details.Info;
    $name = $info.Name -replace $info.Extension, "";
    return @{
        Name    = $name
        Info    = $info
        Details = $details
        Imdb    = $imdbCache[$details.Title];
    }
} | Where-Object {
    return $null -ne $_;
};

if ($subs.Length -gt 0) { 
    HandleMovies -subs $subs;
    HandleSeries -subs $subs;
}

timeout.exe 10;