[CmdletBinding()]
param (
    [PsObject]$Show,
    [string]$Quality,
    [string]$SavePath,
    [string]$RenameTo,
    [string[]]$IgnoredVersions,
    [string[]]$Keywords
)

# Docs: https://subdl.com/api-doc
$BaseApi = "https://api.subdl.com/api/v1/subtitles";
# Please Don't Steal this, it won't Help you at all. I'm lazy to secure it :)
$NotWhatYouThink = "eKncI_x3dQ7edsGA6GvEKJ3mgyXEGe9u"

$Type = $Show.Type;
$Title = $Show.Title;
# $Year = $Show.Year;
$Season = $Show.Season;
$ShowImdbId = $Show.ImdbId;
$Episodes = $Show.Episodes;

function GetInfo {
    # Please Don't Steal this, it won't Help you at all. I'm lazy to secure it :)$QueryString = "api_key
    =$NotWhatYouThink&imdb_id=$ShowImdbId&languages=AR&subs_per_page=30"

    if ($Season) {
        $QueryString += "&season_number=$Season"; 
    }

    try {
        $Response = Invoke-WebRequest `
            -Method Get `
            -Uri "$($BaseApi)?$($QueryString)"    
        return $Response.Content | ConvertFrom-Json;
    }
    catch {
        $response = $_.Exception.Response;
        Write-Host "Error: $($response.StatusCode) - $($_.Exception.Message)" -ForegroundColor Red;
    }
    
}

$Info = GetInfo;
$Subtitles = $Info.subtitles
if ($Type -eq "Movie") {
    return @{}
}

$Episodes | ForEach-Object {
    $episode = $_;
    $sub = $Subtitles | Where-Object { 
        $_.Episode -ge $_.episode_from -and `
            $_.Episode -le $_.episode_end
    } | Select-Object -First 1

    $subtitlePath = & "$PSScriptRoot\Shared\Download-Subtitle.ps1" `
        -DownloadRequestArgs (@{
            Uri = "https://dl.subdl.com$($sub.url)"
        });

    & "$PSScriptRoot\Shared\Copy-Subtitle.ps1" `
        -SubtitlePath $subtitlePath `
        -SavePath $episode.SavePath `
        -RenameTo $episode.RenameTo `
        -EpisodeRegex $episodeRegex `
        -QualityRegex $qualityRegex
}


