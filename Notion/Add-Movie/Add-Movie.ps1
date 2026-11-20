[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments)]
    [string[]]
    $Files
)

$dataSourceId = "218d7e27-7324-81f4-aa48-000b5428f581";
$token = Get-ShellSecret.ps1 -Name "Notion:ApiKey";
if (!$token) {
    Write-Host "Missing secret Notion:ApiKey. Run: Set-ShellSecret.ps1 -Name 'Notion:ApiKey' -secret '<integration token>'" -ForegroundColor Red;
    return;
}

$headers = @{
    "Authorization"  = "Bearer $token"
    "Notion-Version" = "2025-09-03"
    "Content-Type"   = "application/json; charset=utf-8"
};

function Invoke-Notion {
    param ($Uri, $Method = "Post", $Body)

    $params = @{ Uri = "https://api.notion.com/v1/$Uri"; Method = $Method; Headers = $headers };
    if ($Body) {
        $params.Body = [System.Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Depth 10));
    }
    return Invoke-RestMethod @params;
}

function Get-NormalizedTitle {
    param ($Title)

    return ($Title.ToLower() -replace "&", "and" -replace "[^\p{L}\p{Nd}]", "");
}

function Get-NotionMovies {
    $movies = @();
    $cursor = $null;
    do {
        $body = @{ page_size = 100 };
        if ($cursor) { $body.start_cursor = $cursor }
        $res = Invoke-Notion -Uri "data_sources/$dataSourceId/query" -Body $body;
        foreach ($page in $res.results) {
            $title = ($page.properties.Name.title.plain_text -join "");
            $movies += @{
                Title      = $title
                Normalized = Get-NormalizedTitle -Title $title
                Year       = ($page.properties.Year.rich_text.plain_text -join "")
                Url        = $page.url
            };
        }
        $cursor = $res.has_more ? $res.next_cursor : $null;
    } while ($cursor);

    return $movies;
}

function Get-ImdbRate {
    param ($Id)

    $res = Invoke-WebRequest "https://www.imdb.com/title/$Id";
    if ($res.Content -match '"ratingValue": ?(?<Rate>\d+\.\d+)') {
        return [double]$Matches["Rate"];
    }
}

$videos = @($Files | Where-Object { Is-Video.ps1 $_ });
if ($videos.Count -eq 0) {
    Write-Host "No video files selected." -ForegroundColor Yellow;
    return;
}

Write-Host "Loading genres and movies from Notion..." -ForegroundColor Cyan;
$schema = Invoke-Notion -Uri "data_sources/$dataSourceId" -Method Get;
$genres = @($schema.properties.Genre.multi_select.options.name);
$movies = Get-NotionMovies;
Write-Host "Found $($movies.Count) movies in Notion." -ForegroundColor Cyan;
$handled = @{};

foreach ($file in $videos) {
    $details = Get-ShowDetails.ps1 -Path $file;
    Write-Host "`nFile: $([System.IO.Path]::GetFileName($file))" -ForegroundColor Cyan;
    Write-Host "Parsed: $($details.Title) ($($details.Year))";
    Write-Host "Searching IMDb...";
    $show = Imdb-GetShow.ps1 -Name $details.Title -Year $details.Year -Type $details.Type;
    if (!$show) {
        Write-Host "Could not find '$($details.Title)' on IMDb." -ForegroundColor Red;
        continue;
    }
    if ($show.Type -ne "Movie") {
        Write-Host "'$($show.Title)' is not a movie, skipped." -ForegroundColor Yellow;
        continue;
    }
    if ($handled[$show.Id]) { continue }
    $handled[$show.Id] = $true;

    Write-Host "IMDb: $($show.Title) ($($show.Year)) $($show.Id)" -ForegroundColor Green;
    Write-Host "Checking if it is already in Notion...";
    $normalized = Get-NormalizedTitle -Title $show.Title;
    $existing = @($movies | Where-Object {
            $_.Normalized -eq $normalized -and (!$_.Year -or !$show.Year -or $_.Year -eq "$($show.Year)")
        });
    if ($existing.Count -gt 0) {
        $list = ($existing | ForEach-Object { "$($_.Title) ($($_.Year)) - $($_.Url)" }) -join "`n";
        $continue = Prompt.ps1 -Title "Already in Notion" -Message "'$($show.Title)' ($($show.Year)) is already in Notion:`n$list`n`nAdd it anyway?" -DefaultValue $false;
        if (!$continue) {
            Write-Host "'$($show.Title)' is already added." -ForegroundColor Yellow;
            continue;
        }
    }

    $selectedGenres = @(Multi-Options-Selector.ps1 -Options $genres -Multi -Title "Genres for $($show.Title) ($($show.Year))");
    $comment = Input.ps1 -Title "Comment" -Message "Comment for $($show.Title) (leave empty for none)";

    Write-Host "Getting the IMDb rate...";
    $rate = Get-ImdbRate -Id $show.Id;
    $summary = "Name: $($show.Title)`nYear: $($show.Year)`nRate: $rate`nGenre: $($selectedGenres -join ', ')`nComment: $comment";
    if (!(Prompt.ps1 -Title "Add to Notion" -Message "$summary`n`nAdd this movie to Notion?" -DefaultValue $false)) {
        Write-Host "'$($show.Title)' was not added." -ForegroundColor Yellow;
        continue;
    }

    $properties = @{
        Name  = @{ title = @(@{ text = @{ content = $show.Title } }) }
        Year  = @{ rich_text = @(@{ text = @{ content = "$($show.Year)" } }) }
        Genre = @{ multi_select = @($selectedGenres | Where-Object { $_ } | ForEach-Object { @{ name = $_ } }) }
    };
    if ($comment) {
        $properties.Comment = @{ rich_text = @(@{ text = @{ content = $comment } }) };
    }
    if ($rate) {
        $properties.Rate = @{ number = $rate };
    }

    Write-Host "Adding to Notion...";
    $page = Invoke-Notion -Uri "pages" -Body @{
        parent     = @{ type = "data_source_id"; data_source_id = $dataSourceId }
        properties = $properties
    };
    $movies += @{ Title = $show.Title; Normalized = $normalized; Year = "$($show.Year)"; Url = $page.url };
    Write-Host "Added '$($show.Title)' ($($show.Year)) with rate $rate to Notion." -ForegroundColor Green;
}

Timeout.ps1 10;