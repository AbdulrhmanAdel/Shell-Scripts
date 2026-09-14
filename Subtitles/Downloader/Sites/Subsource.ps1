# Docs: https://subsource.net/api-docs
$SubsourceApiKey = Get-ShellSecret.ps1 -Name "Subsource:ApiKey";
$SubsourceHeaders = @{ "X-API-Key" = $SubsourceApiKey }
$SubsourceBaseUrl = 'https://api.subsource.net/api/v1'

function InvokeSubsourceRequest {
    param (
        $Path
    )

    try {
        $response = Invoke-WebRequest -Uri "$SubsourceBaseUrl/$Path" `
            -Headers $SubsourceHeaders `
            -UseBasicParsing
        return $response.Content | ConvertFrom-Json;
    }
    catch {
        $response = $_.Exception.Response;
        Write-Host "Error: $($response.StatusCode) - $($_.Exception.Message)" -ForegroundColor Red;
    }
}

function Find-Show {
    param (
        $Show
    )

    Write-Host "Using Subsource API" -ForegroundColor Magenta;

    $result = InvokeSubsourceRequest -Path "movies/search?searchType=imdb&imdb=$($Show.ImdbId)";
    $data = $result.data;
    $movieOrShow = $Show.Season `
        ? ($data | Where-Object { $_.season -eq $Show.Season } | Select-Object -First 1) `
        : $data[0];

    Write-Host "[INFO]: Found Movie/Show:" -ForegroundColor Cyan;
    Write-Host "[INFO]: ID: $($movieOrShow.movieId)" -ForegroundColor Cyan;
    Write-Host "[INFO]: Title: $($movieOrShow.title)" -ForegroundColor Cyan;
    if ($movieOrShow.season) {
        Write-Host "[INFO]: Season: $($movieOrShow.season)" -ForegroundColor Cyan;
    }

    return @{
        MovieId = $movieOrShow.movieId
        PageUrl = $movieOrShow.subsourceLink
    }
}

function Get-SubtitleCandidates {
    param (
        $ShowHandle
    )

    $result = InvokeSubsourceRequest -Path "subtitles?movieId=$($ShowHandle.MovieId)&language=arabic&limit=100";
    return $result.data | ForEach-Object {
        @{
            Data     = $_
            KeyWords = @($_.releaseInfo) + @($_.releaseType)
        }
    }
}

function Get-SubtitleDownloadArgs {
    param (
        $Subtitle
    )

    return @{
        Uri     = "$SubsourceBaseUrl/subtitles/$($Subtitle.subtitleId)/download"
        Headers = $SubsourceHeaders
    }
}
