# Docs: https://subdl.com/api-doc
$SubdlApiKey = Get-ShellSecret.ps1 -Name "Subdl:ApiKey";
$SubdlBaseUrl = 'https://api.subdl.com/api/v1/subtitles'
$SubdlOrdinals = @(
    "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth",
    "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth", "eighteenth", "nineteenth", "twentieth"
)

function Get-SubdlSeasonSlug {
    param (
        $Season
    )

    if ($Season -ge 1 -and $Season -le $SubdlOrdinals.Length) {
        return "$($SubdlOrdinals[$Season - 1])-season"
    }

    return "season-$Season"
}

function Get-SubdlSlug {
    param (
        [string]$Name
    )

    return ($Name.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
}

function Find-Show {
    param (
        $Show
    )

    $query = "api_key=$SubdlApiKey&imdb_id=$($Show.ImdbId)&languages=AR&subs_per_page=30";
    if ($Show.Season) {
        $query += "&season_number=$($Show.Season)";
    }

    try {
        $response = Invoke-WebRequest -Method Get -Uri "${SubdlBaseUrl}?$query" -UseBasicParsing;
        $result = $response.Content | ConvertFrom-Json;
    }
    catch {
        $response = $_.Exception.Response;
        Write-Host "Error: $($response.StatusCode) - $($_.Exception.Message)" -ForegroundColor Red;
        return @{ RawSubtitles = @() }
    }

    $showResult = $result.results | Select-Object -First 1;
    $pageUrl = $null;
    if ($showResult.sd_id -and $showResult.name) {
        $pageUrl = "https://subdl.com/subtitle/sd$($showResult.sd_id)/$(Get-SubdlSlug -Name $showResult.name)";
        if ($Show.Season) {
            $pageUrl += "/$(Get-SubdlSeasonSlug -Season $Show.Season)";
        }
    }

    return @{
        RawSubtitles = $result.subtitles
        PageUrl      = $pageUrl
    }
}

function Get-SubtitleCandidates {
    param (
        $ShowHandle
    )

    return $ShowHandle.RawSubtitles | ForEach-Object {
        $sub = $_;
        $episodeTokens = @();
        if ($sub.episode_from -and $sub.episode_end) {
            $episodeTokens = $sub.episode_from..$sub.episode_end | ForEach-Object { "-E$('{0:D2}' -f $_)." }
        }

        @{
            Data     = $sub
            KeyWords = @($sub.release_name) + $episodeTokens
        }
    }
}

function Get-SubtitleDownloadArgs {
    param (
        $Subtitle
    )

    return @{
        Uri = "https://dl.subdl.com$($Subtitle.url)"
    }
}
