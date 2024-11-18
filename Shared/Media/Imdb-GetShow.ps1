[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$name,
    $year,
    $type
)

# function Search {
#     param (
#         $key
#     )

#     If (-not (Get-Module -ErrorAction Ignore -ListAvailable PSParseHTML)) {
#         Write-Verbose "Installing PSParseHTML module for the current user..."
#         Install-Module -Scope CurrentUser PSParseHTML -ErrorAction Stop
#     }
      
#     $text = ConvertFrom-Html -Engine AngleSharp -Url "https://www.imdb.com/find/?q=$key";
#     $titles = $text.QuerySelectorAll(".ipc-metadata-list-summary-item");
#     $titles | ForEach-Object { 
#         $details = $_.QuerySelector('.ipc-metadata-list-summary-item__tc');
#         $moviesNameNode = $details.QuerySelector('a')
#         $moviesId = $moviesNameNode.PathName.Replace("/title/", "").Replace("/", "");
#         $moviesName = $moviesNameNode.TextContent;
#         $year = $details.QuerySelector('ul li:nth-child(1)').TextContent; ;
#         $kind = $details.QuerySelector('ul li:nth-child(2)').TextContent; ;
        
#         return @{
#             Id    = $moviesId
#             Title = $moviesName
#             Year  = $year
#             Kind  = $kind
#         };
#     }
# }


function Prompt {
    param (
        $Infos
    )

    return Single-Options-Selector.ps1 -Options @(
        $Infos | ForEach-Object {
            return @{
                Key   = "$($_.id) $($_.l) $($_.y) $($_.qid)"
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