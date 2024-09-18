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
            return $_.y -eq $Year;
        }

        return $sameType;
    } | Select-Object -First 1;
    $matchededShow ??= $json.d[0];
    return $matchededShow;
}

return GetShow -Name $name -Year $year -Type $type;