$replaceText = "\[(FitGirl|Dodi).*\]|-.*Edition";
$args | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object {
    $hasIcon = Get-ChildItem -LiteralPath $_ -Filter "*.ico" -Force;
    if ($hasIcon) {
        $overwrite = & Prompt.ps1 -Title "Folder Already has icon. do you want to overwrite it?";
        if (!$overwrite) {
            return
        }
    }
    $info = Get-Item -LiteralPath $_;
    $name = $info.Name -replace $replaceText, "";
    Write-Host "HANDLING ICON FOR $_" -ForegroundColor Green;
    $url = [System.Web.HttpUtility]::UrlEncode($info.FullName);

    $isGame = $info.FullName.Contains("Game");
    Write-Host $url;
    Start-Process "https://www.google.com/search?tbm=isch&q=$($name) $($isGame ? 'Game' : '') PNG Icon&path=$url";
}

# timeout.exe  /nobreak;