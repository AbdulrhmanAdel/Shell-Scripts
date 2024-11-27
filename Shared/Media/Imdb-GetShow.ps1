[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$name,
    $year,
    $type
)

function Prompt {
    param (
        $Infos
    )

    if ($Infos.Length -eq 1) {
        return $Infos[0];
    }

    return Single-Options-Selector.ps1 -Options @(
        $Infos | ForEach-Object {
            return @{
                Key   = "$($_.id) - $($_.l) - $($_.y) - $($_.qid)"
                Value = $_
            }
        }
    ) -Title "Found Multi Possible Shows matched your criteria please select one";
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
        $sameTypes = $json.d | Where-Object {
            return $_.qid -match $type;
        } 
        
        $exactTitles = @($sameTypes |  Where-Object { 
                return $_.l -eq $Name;
            });

        if ($exactTitles.Length -eq 1) {
            return $exactTitles[0];
        }

        if ($exactTitles.Length -gt 1) {
            $hasSameYear = $exactTitles | Where-Object { HasSameYear -Info $_ } | Select-Object -First 1;
            if ($hasSameYear) {
                return $hasSameYear;
            }

            $found = Prompt -Infos $exactTitles;
            if ($found) {
                return $found;
            }
        }

        return Prompt -Infos $sameTypes;
    }
    catch {
        return $null;
    }
    
}

return GetShow -Name $name -Year $year -Type $type;