[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths
)


function HandleMovies {
    param($subs)
    $movies = $subs | Where-Object { $_.Details.Type -eq "Movie" };
    $movies | Where-Object {
        $info = $_.Info;
        $details = $_.Details;
        $imdb = $imdbCache[$details.Title];
        Write-Host $details;    
        & "$($PSScriptRoot)/Sites/Subsource.ps1" `
            -DownloadPath $downloadPath `
            -Type $details.Type `
            -Title $details.Title `
            -Quality $details.Quality `
            -SavePath $info.Directory.FullName `
            -RenameTo $_.Name `
            -Year $details.Year `
            -IgnoredVersions $details.IgnoredVersions `
            -Keywords $details.Keywords `
            -ShowImdbId $imdb.Id;
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
            ShowId          = $episode.Imdb.Id
        }
    }

    $series | ForEach-Object { GroupSeries -episode $_ };
    $final.Keys | ForEach-Object {
        $showName = $_;
        $show = $final[$_];
        $show.Keys | Where-Object { $_ -ne "ShowId" } | ForEach-Object {
            $seasonEpisodes = $show[$_] | Sort-Object -Property Episode;
            $episodeWithYear = $seasonEpisodes | Where-Object { !!$_.Year } | Select-Object -First  1;
            & "$($PSScriptRoot)/Sites/Subsource.ps1" `
                -DownloadPath $downloadPath `
                -Type "Series" `
                -Title $showName `
                -Season $_ `
                -Year $episodeWithYear.Year `
                -Episodes $seasonEpisodes `
                -ShowImdbId $show.ShowId; 
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
            if ($hasArabicSoftSub) {
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
        $imdbCache[$details.Title] = Imdb-GetShow.ps1 -name $details.Title;
    }
    if (!$details) { return $null; }
    $imdb = $imdbCache[$details.Title];
    $details.Type = $imdb.type;
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
    $downloadPath = "$($env:TEMP)/MyScripts/Subtitle-Downloader";
    if (!(Test-Path -LiteralPath $downloadPath)) {
        New-Item -Path $downloadPath -ItemType Directory -Force;
    }
    HandleMovies -subs $subs;
    HandleSeries -subs $subs;
    Remove-Item  -LiteralPath $downloadPath -Force -Recurse;
}

timeout.exe 10;