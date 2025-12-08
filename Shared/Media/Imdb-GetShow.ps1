[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$name,
    $Year,
    $Type,
    [System.IO.FileInfo]$FileInfo
)

function GetIdUsingAI {
    $fileName = $FileInfo ? $FileInfo.Name : $Name;
    $apiKey = "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"
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "application/json"
    }

    $body = @{
        "input"       = "Only output single word Taking this file name \'$fileName\' Output imdb id "
        "model"       = "tngtech/deepseek-r1t2-chimera:free"
        "temperature" = 0.7
        "top_p"       = 0.9
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod `
        -Uri "https://openrouter.ai/api/v1/responses" `
        -Method Post `
        -Headers $headers `
        -Body $body

    $content = $response.output | Where-Object { $_.role -eq "assistant" } | Select-Object -First 1;
    return $content.content[0].text    
}


function InvokeImdb {
    param (
        $searchQuery
    )


    $res = Invoke-WebRequest -Uri "https://v3.sg.media-imdb.com/suggestion/x/$searchQuery.json?includeVideos=1"
    $json = $res.Content | ConvertFrom-Json
    return $json.d;
}

function GetShowByQueryImdb {
    $final = InvokeImdb -searchQuery $Name;
    $exactTitles = @(
        $final |  Where-Object { 
            return $_.l -eq $Name;
        }
    );
    if ($exactTitles.Length -gt 0) {
        $final = $exactTitles;
    }
    if ($Year) {
        $sameYear = @(
            $final | Where-Object { HasSameYear -Info $_ };
        );
        if ($sameYear.Length -gt 0) {
            $final = $sameYear;
        }
    }

    if ($final.Length -eq 1) {
        return $final[0];
    }
    
    return Single-Options-Selector.ps1 -Options @(
        $final | ForEach-Object {
            return @{
                Key   = "$($_.id) - $($_.l) - $($_.y) - $($_.qid)"
                Value = $_
            }
        }
    ) -Title "Found Multi Possible Shows matched your criteria please select one with name $name";   
}

if (-not $name) {
    Write-Host "Please provide a path or a name to search for."
    return $null;
}

function HasSameYear {
    param (
        $Info
    )
    
    if (!!$Year) {
        return $Info.y -eq $Year;
    }

    return $false;
}

function GetShow {
    param (
        $Name,
        $Year,
        $Type
    )
    try {
        $showId = GetIdUsingAI -fileName $Name
        if ($showId) {
            $result = InvokeImdb -searchQuery $showId
            return $result[0];
        }
        
        return GetShowByQueryImdb;
    }
    catch {
        return $null;
    }
}

$show = GetShow -Name $name -Year $Year -Type $Type;
if (!$show) {
    return $null;
}

return @{
    Id    = $show.id
    Year  = $show.y
    Title = $show.l
    Type  = $show.qid -eq 'movie' ? 'Movie' : 'Series'
}