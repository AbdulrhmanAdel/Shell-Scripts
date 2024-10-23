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

function GetShow {
    param (
        $Name,
        $Year,
        $Type
    )

    try {
        $res = Invoke-WebRequest -Uri "https://v3.sg.media-imdb.com/suggestion/x/$Name.json?includeVideos=1"
        $json = $res.Content | ConvertFrom-Json;
        $matchededShow = $json.d | Where-Object {
            $sameType = $_.qid -match $type;
            if (!$sameType) { return $false }
            if (!!$Year) {
                return $_.y -eq $Year;
            }

            return $sameType;
        } | Select-Object -First 1;
        $matchededShow ??= $json.d[0];
        return $matchededShow;
    }
    catch {
        return $null;
    }
    
}

return GetShow -Name $name -Year $year -Type $type;