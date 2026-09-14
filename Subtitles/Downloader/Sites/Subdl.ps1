# Docs: https://subdl.com/api-doc
$SubdlApiKey = Get-ShellSecret.ps1 -Name "Subdl:ApiKey";
$SubdlBaseUrl = 'https://api.subdl.com/api/v1/subtitles'

function Find-Show {
    param (
        $Show
    )

    $query = "api_key=$SubdlApiKey&imdb_id=$($Show.ImdbId)&languages=AR&subs_per_page=30";
    if ($Show.Season) {
        $query += "&season_number=$($Show.Season)";
    }

    return @{
        Query = $query
    }
}

function Get-SubtitleCandidates {
    param (
        $ShowHandle
    )

    try {
        $response = Invoke-WebRequest -Method Get -Uri "${SubdlBaseUrl}?$($ShowHandle.Query)" -UseBasicParsing;
        $result = $response.Content | ConvertFrom-Json;
    }
    catch {
        $response = $_.Exception.Response;
        Write-Host "Error: $($response.StatusCode) - $($_.Exception.Message)" -ForegroundColor Red;
        return @()
    }

    return $result.subtitles | ForEach-Object {
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
