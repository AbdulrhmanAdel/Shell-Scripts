. Parse-Args.ps1 $args;

function GetShow {
    param (
        $Name,
        $Year,
        $Type
    )

    $res = Invoke-WebRequest -Uri "https://v3.sg.media-imdb.com/suggestion/x/$Name.json?includeVideos=1"
    $json = $res.Content | ConvertFrom-Json;
    $matchededShow = $json.d | Where-Object {
        $sameType = $_.qid -match $type;
        if (!$sameType) { return $false }
        if (!!$Year) {
            $hasSameYear = $_.y -eq $Year;
            if ($hasSameYear -and !!$Type) {
                return 
            }    
        
            return $hasSameYear;
        }

        return $sameType;
    } | Select-Object -First 1;
    $matchededShow ??= $json.d[0];
    return $matchededShow;
}

return GetShow -Name $name -Year $year -Type $type;