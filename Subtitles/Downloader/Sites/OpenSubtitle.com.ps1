# DOCS https://opensubtitles.stoplight.io/
$OpenSubtitlesApiKey = Get-ShellSecret.ps1 -Name "OpenSubtitles:ApiKey";
$OpenSubtitlesBaseUrl = 'https://api.opensubtitles.com/api/v1'
$OpenSubtitlesUserAgent = 'ShellScripts-SubtitleDownloader v1.0.0'
$OpenSubtitlesToken = $null

function Get-OpenSubtitlesHeaders {
    param (
        [switch]$Authenticated
    )

    $headers = @{
        "Api-Key"      = $OpenSubtitlesApiKey
        "User-Agent"   = $OpenSubtitlesUserAgent
        "Content-Type" = "application/json"
    }

    if ($Authenticated) {
        $headers["Authorization"] = "Bearer $(Get-OpenSubtitlesToken)"
    }

    return $headers
}

function Get-OpenSubtitlesToken {
    if ($script:OpenSubtitlesToken) {
        return $script:OpenSubtitlesToken
    }

    $username = Get-ShellSecret.ps1 -Name "OpenSubtitles:Username";
    $password = Get-ShellSecret.ps1 -Name "OpenSubtitles:Password";
    $body = @{ username = $username; password = $password } | ConvertTo-Json;

    try {
        $response = Invoke-WebRequest -Uri "$OpenSubtitlesBaseUrl/login" `
            -Method Post `
            -Headers (Get-OpenSubtitlesHeaders) `
            -Body $body `
            -UseBasicParsing;
        $result = $response.Content | ConvertFrom-Json;
        $script:OpenSubtitlesToken = $result.token;
        return $script:OpenSubtitlesToken;
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red;
    }
}

function Find-Show {
    param (
        $Show
    )

    $imdbId = $Show.ImdbId -replace '^tt0*', '';

    return @{
        ImdbId  = $imdbId
        Season  = $Show.Season
        PageUrl = "https://www.opensubtitles.com/en/search/imdbid-$imdbId"
    }
}

function Get-SubtitleCandidates {
    param (
        $ShowHandle
    )

    $query = "languages=ar";
    if ($ShowHandle.Season) {
        $query += "&parent_imdb_id=$($ShowHandle.ImdbId)&season_number=$($ShowHandle.Season)";
    }
    else {
        $query += "&imdb_id=$($ShowHandle.ImdbId)";
    }

    try {
        $response = Invoke-WebRequest -Uri "$OpenSubtitlesBaseUrl/subtitles?$query" `
            -Headers (Get-OpenSubtitlesHeaders) `
            -UseBasicParsing;
        $result = $response.Content | ConvertFrom-Json;
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red;
        return @()
    }

    return $result.data | ForEach-Object {
        $attributes = $_.attributes;
        @{
            Data     = $attributes
            KeyWords = @($attributes.release) + @($attributes.files.file_name)
        }
    }
}

function Get-SubtitleDownloadArgs {
    param (
        $Subtitle
    )

    $body = @{ file_id = $Subtitle.files[0].file_id } | ConvertTo-Json;

    try {
        $response = Invoke-WebRequest -Uri "$OpenSubtitlesBaseUrl/download" `
            -Method Post `
            -Headers (Get-OpenSubtitlesHeaders -Authenticated) `
            -Body $body `
            -UseBasicParsing;
        $result = $response.Content | ConvertFrom-Json;
        if ($null -ne $result.remaining) {
            Write-Host "[INFO]: OpenSubtitles downloads remaining today: $($result.remaining)" -ForegroundColor DarkGray;
        }
        return @{ Uri = $result.link }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red;
        return @{ Uri = $null }
    }
}
