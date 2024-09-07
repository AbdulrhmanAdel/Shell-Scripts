$replaceText = "\[(FitGirl|Dodi).*\]";
$args | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object {
    $hasIcon = Get-ChildItem -LiteralPath $_ -Filter "*.ico" -Force;
    if ($hasIcon) {
        Write-Host "Folder Has ICON $_" -ForegroundColor Red;
        return;
    }
    $info = Get-Item -LiteralPath $_;
    $name = $info.Name -replace $replaceText, "";
    Write-Host "HANDLING ICON FOR $_" -ForegroundColor Green;
    $url = [System.Web.HttpUtility]::UrlEncode($info.FullName)
    Write-Host $url;
    Start-Process "https://www.google.com/search?tbm=isch&q=$($name) Game PNG Icon&path=$url";
}

timeout.exe 15 /nobreak;