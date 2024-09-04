

function GetShow {
    param (
        $ShowName,
        $ShowYear
    )

    $res = Invoke-WebRequest -Uri "https://v3.sg.media-imdb.com/suggestion/x/$ShowName.json?includeVideos=1"
    $json = $res.Content | ConvertFrom-Json;
    return $json.d | Where-Object { $_.y -eq $ShowYear } | Select-Object -First 1;
}



function AddToWatchList {
    param (
        $show
    )
    $showId = $show.id;
    # Get New One From IDMB

    if ($res.StatusCode -eq 200) {
        Write-Host "$($show.l)" -NoNewline -ForegroundColor Green;
        Write-Host " added To Watch List Successfuly"
        return $true;
    }
    else {
        Write-Host $res;
        return $false;
    }
}

$shows = @();

$erroredShows = @();
$shows | ForEach-Object {
    $show = GetShow -ShowName $_[0] -ShowYear $_[1]
    if (!$show) {
        $erroredShows += $_;
        return
    }

    if (!(AddToWatchList -Show $show)) {
        $erroredShows += $_;
        return
    }
    
}
Write-Host "TESTINGH"
