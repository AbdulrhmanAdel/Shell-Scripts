[CmdletBinding()]
param (
    [PsObject]$Show,
    [string]$Quality,
    [string]$SavePath,
    [string]$RenameTo,
    [string[]]$IgnoredVersions,
    [string[]]$Keywords
)


$Type = $Show.Type;
$Title = $Show.Title;
# $Year = $Show.Year;
$Season = $Show.Season;
$ShowImdbId = $Show.ImdbId;
$Episodes = $Show.Episodes;

$global:subtitlePageLink = "";
$openedSites = @();
Write-Host "Using Subsource API" -ForegroundColor Magenta;
Write-Host "==============================" -ForegroundColor Red;
Write-Host "Handling: " -ForegroundColor Green -NoNewline;
Write-Host "$title " -ForegroundColor DarkBlue -NoNewline;
Write-Host "Type: $type " -ForegroundColor Green -NoNewline;
if ($type -eq "Series") {
    Write-Host "Season: $Season; " -ForegroundColor Green -NoNewline;
    Write-Host "Episodes: " -ForegroundColor Green -NoNewline;
    Write-Host ($Episodes | ForEach-Object { return $_.Episode }) -Separator ", " -ForegroundColor Green -NoNewline;
}
Write-Host ""


# Subsource Urls
# https://subsource.net/api-docs
# # $baseUrl = "https://api.subsource.net/v1";
# $subsourceSiteDomain = "https://subsource.net";
# Please Don't Steal this, it won't Help you at all. I'm lazy to secure it :)
$Blah = 'sk_e1003cb739a8154811b28d42ff6247ad76701cdedeaa87adf1a6dffe5639080c';
$BlahHeaders = @{ "X-API-Key" = $Blah }
$baseApiURL = 'https://api.subsource.net/api/v1'

#region Functions

function InvokeAPIRequest {
    param (
        $Path
    )

    try {
        $response = Invoke-WebRequest -Uri "$baseApiURL/$Path" `
            -Headers $BlahHeaders `
            -UseBasicParsing
        return $response.Content | ConvertFrom-Json;
    }
    catch {
        $response = $_.Exception.Response;
        Write-Host "Error: $($response.StatusCode) - $($_.Exception.Message)" -ForegroundColor Red;
    }
}

function GetSubtitleDownloadArgs {
    param (
        $Subtitle
    )

    return @{
        Uri     = "$baseApiURL/subtitles/$($Subtitle.subtitleId)/download"
        Headers = $BlahHeaders
    }
}

function SearchMovie() {
    $result = InvokeAPIRequest -Path "movies/search?searchType=imdb&imdb=$ShowImdbId"
    return $result.data[0];
}

function GetSubtitles {
    param (
        $MovieOrShow
    )
    $result = InvokeAPIRequest -Path "subtitles?movieId=$($MovieOrShow.movieId)&language=arabic&limit=100"
    return $result.data;
}

$movieOrShow = SearchMovie;
$subs = GetSubtitles -MovieOrShow $movieOrShow | ForEach-Object {
    return @{
        Data     = $_
        KeyWords = $_.releaseInfo + @($_.releaseType)
    }
};

# TODO: Handle All Season Subtitles 
# $allSeasonSubs = $subs;
$availableSubs = $subs;
if ($type -eq "Movie") {
    $matchResult = & "$PSScriptRoot\Shared\Match-Release.ps1" -Subtitles $availableSubs `
        -IgnoredVersions $IgnoredVersions `
        -Keywords $Keywords;
    
    if (!$matchResult.hasMatch) {
        Write-Host "No exact match found, trying loose matching..." -ForegroundColor Yellow;
        return;       
    }

    $downloadPath = & "$PSScriptRoot\Shared\Download-Subtitle.ps1" `
        -DownloadRequestArgs (GetSubtitleDownloadArgs -Subtitle $matchResult.FirstMatch.Data);

    & "$PSScriptRoot\Shared\Copy-Subtitle.ps1" `
        -SubtitlePath $downloadPath `
        -SavePath $SavePath `
        -RenameTo $RenameTo `
        -QualityRegex $Quality;
    return
}

$wholeSeasonRegex = "(S0$Season)([^EX0-9]|$)|" + `
    "(S0$Season)(\.| \[)?(1080P|720P|480P)|" + `
    "(S0$Season)E\d\d*(>|~)E\d\d*";
$wholeSeasonSubtitles = @(
    $availableSubs | Where-Object {
        return $_.release_info -replace "\.| ", "" -match $wholeSeasonRegex `
            -or $_.commentary -contains "الموسم كامل" `
            -or $_release_info -match "Complete(\.| )?Season"
    }
);

$availableSubs = $availableSubs | Where-Object { $_ -notin $wholeSeasonSubtitles };
$Episodes | ForEach-Object {
    $episode = $_;
    Write-Host "-----" -ForegroundColor Yellow;
    Write-Host "Episode $($episode.Episode)" -ForegroundColor Yellow;
    $episodeNumber = $episode.Episode;
    $qualityRegex = $episode.Quality
    $episodeRegex = $null;
    if ($Title -contains $episodeNumber) {
        $episodeRegex = "(S?0*$Season)?(\.| )*(E|\d+X|Episode|EP)0*$episodeNumber(\D+|$)"
    }
    else {
        $episodeNumberGtNine = $episodeNumber -gt 9;
        $episodeRegex = "(\.|\|| |-|E)$($episodeNumberGtNine ? $episodeNumber : "0*$episodeNumber")(\.| |-|\|)"
    }

    $keyWords = @(
        $episodeRegex
        $episode.Keywords
        $qualityRegex
    );

    $matchResult = & "$PSScriptRoot\Shared\Match-Release.ps1" -Subtitles $availableSubs `
        -IgnoredVersions $IgnoredVersions `
        -Keywords $keyWords;

    if (!$matchResult.hasMatch) {
        Write-Host "CAN'T FIND Subtitle FOR $title => EPISODE $episodeNumber " -ForegroundColor Red -NoNewLine;
        Write-Host "$global:subtitlePageLink" -ForegroundColor Blue;
        $link = $movieOrShow.subsourceLink;
        if ($openedSites -notcontains $link) {
            $openedSites += $link;
            Start-Process $link; 
        }
        [Console]::Beep(1000, 500);
        return;
    }
    
    $subtitlePath = & "$PSScriptRoot\Shared\Download-Subtitle.ps1" `
        -DownloadRequestArgs (GetSubtitleDownloadArgs -Subtitle $matchResult.FirstMatch.Data);

    & "$PSScriptRoot\Shared\Copy-Subtitle.ps1" `
        -SubtitlePath $subtitlePath `
        -SavePath $episode.SavePath `
        -RenameTo $episode.RenameTo `
        -EpisodeRegex $episodeRegex `
        -QualityRegex $qualityRegex
}

Write-Host "==============================" -ForegroundColor Red;