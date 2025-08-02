[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$name,
    $Year,
    $Type
)

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
        $res = Invoke-WebRequest -Uri "https://v3.sg.media-imdb.com/suggestion/x/$Name.json?includeVideos=1"
        $json = $res.Content | ConvertFrom-Json
        $final = $json.d;
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