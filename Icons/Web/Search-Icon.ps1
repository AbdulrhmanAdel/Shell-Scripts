$args | ForEach-Object {
    $info = Get-Item -LiteralPath $_;

    $url = [System.Web.HttpUtility]::UrlEncode($info.FullName)
    Write-Host $url;
    Start-Process "https://www.google.com/search?tbm=isch&q=$($info.Name) Game PNG Icon&path=$url";
}