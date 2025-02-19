function Get-DownloadLinks {
    param (
        [string]$Link
    )

    $uri = [uri]$Link;
    $origin = "$($uri.Scheme)://$($uri.Host)";
    $path = [System.Web.HttpUtility]::UrlEncode($uri.LocalPath);
    $apiUrl = "$($origin)/api/?path=$path";
    $response = curl $apiUrl
    $data = ($response | ConvertFrom-Json).folder.value;
    return $data | ForEach-Object {
        $link = "$origin/api/raw/?path=$($uri.LocalPath)/$($_.name)";
        return $link;
    }
}

Set-Clipboard (Get-DownloadLinks -Link "https://ownl25.cyou/[AniDL]%20Dragon%20Quest%20The%20Adventure%20of%20Dai%20[BD%20720p][DA][hchcsen]");