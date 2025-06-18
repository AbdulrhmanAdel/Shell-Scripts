[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 1)]
    [string]
    $Title
)

function GetEpisodeNumber() {
    param (
        [string]$Name
    )
    $info = Get-ShowDetails.ps1 -Path $Name;
    if ($info.Episode) {
        return $info.Episode;
    }

    if ($info.Title -match "\d+") {
        return [int]::Parse($Matches[0]);
    }

    return $null; 
}

$DownloadedEpisodes = @();
if (Test-Path -LiteralPath $Title) {
    $DownloadedEpisodes = Get-ChildItem -LiteralPath $Title -Include *.mkv | ForEach-Object {
        return GetEpisodeNumber -Name $_.Name;
    } | Where-Object {
        $null -ne $_
    };
    $Title = Split-Path -Path $Title -Leaf;
}

Write-Host "Searching for $Title" -ForegroundColor Green;
$Title = $Title.Trim() -replace "-", " " -replace " +", " " -replace " ", "+";

$Result = curl 'https://anidl.org/wp-admin/admin-ajax.php' `
    -H 'accept: application/json, text/javascript, */*; q=0.01' `
    -H 'accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ar;q=0.6,ru;q=0.5,fr;q=0.4,ko;q=0.3' `
    -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' `
    -b 'cf_clearance=ZHNcQkClZjDyM874HTroao0J2x2TGJo5P1T8maoYCJY-1749930580-1.2.1.1-yVgEFicPJPWqwdFMWqGkBLBXolw1QQ6hkidPrAUr8JT.wq40HKK1_xUzTu.Cy7pzwNRdKc_xwT9KdtIBc62gmFCR6cuSoHAGiW5mbbMy6dCmMWKxtXR50aQfHULsNkKhjJLeIIfirAatyATj1_gxJR1bwRw6jA5Gn6xGGUrHbs5EakQuJLcv1yLp9RLjBqH4GSfKV6RZsajQNc.jwrLQ9_9LtmDtyr6MD4hKUaUMovKbvO6kzMi6IV26e9dbf.G7H654iBndBCJ1xnlAqYRJHF4I8pvaScmNS_oYVK2cepXiaXrdqf8uVr4Lj31quisv4nTpPdeu2D9M9t3Salfa5XhowQCPivbvnIZZCfr1Hyw' `
    -H 'dnt: 1' `
    -H 'origin: https://anidl.org' `
    -H 'priority: u=1, i' `
    -H 'referer: https://anidl.org/airing-anime/' `
    -H 'sec-ch-ua: "Microsoft Edge";v="137", "Chromium";v="137", "Not/A)Brand";v="24"' `
    -H 'sec-ch-ua-arch: "x86"' `
    -H 'sec-ch-ua-bitness: "64"' `
    -H 'sec-ch-ua-full-version: "137.0.3296.83"' `
    -H 'sec-ch-ua-full-version-list: "Microsoft Edge";v="137.0.3296.83", "Chromium";v="137.0.7151.104", "Not/A)Brand";v="24.0.0.0"' `
    -H 'sec-ch-ua-mobile: ?0' `
    -H 'sec-ch-ua-model: ""' `
    -H 'sec-ch-ua-platform: "Windows"' `
    -H 'sec-ch-ua-platform-version: "19.0.0"' `
    -H 'sec-fetch-dest: empty' `
    -H 'sec-fetch-mode: cors' `
    -H 'sec-fetch-site: same-origin' `
    -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0' `
    -H 'x-requested-with: XMLHttpRequest' `
    --data-raw "draw=4&columns%5B0%5D%5Bdata%5D=tv_icon&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=false&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=filename&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=false&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B2%5D%5Bdata%5D=code&columns%5B2%5D%5Bname%5D=&columns%5B2%5D%5Bsearchable%5D=true&columns%5B2%5D%5Borderable%5D=false&columns%5B2%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B2%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B3%5D%5Bdata%5D=date&columns%5B3%5D%5Bname%5D=&columns%5B3%5D%5Bsearchable%5D=true&columns%5B3%5D%5Borderable%5D=false&columns%5B3%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B3%5D%5Bsearch%5D%5Bregex%5D=false&start=0&length=100&search%5Bvalue%5D=$Title&search%5Bregex%5D=false&action=get_mongodb_data"
    
$responseBody = $Result | ConvertFrom-Json;
$data = $responseBody.data;
if ($data.Length -eq 0) {
    Write-Host "No results found" -ForegroundColor Red;
    timeout.exe 5;
}

$links = $data  | Where-Object { $_.filename -match "720p" } | ForEach-Object {
    $fileName = $_.filename;
    $fileName -match "(?<Size>\d+ MBs)" | Out-Null;
    $hasArabicSub = $fileName.Contains("fi fi-sa");
    $size = $matches["Size"];
    $endIndex = $fileName.IndexOf(" <span");
    $fileName = $fileName.Substring(4, $endIndex - 4);
    $link = $_.code;
    $linkEndIndex = $link.IndexOf(""" ");
    $link = $link.Substring(9, $linkEndIndex - 9);
 
    return @{
        Key      = "$fileName $size $hasArabicSub";
        FileName = $fileName
        Value    = $link -replace "#038;", "";
    }
};

if ($DownloadedEpisodes.Length -gt 0) {
    $links = $links | Where-Object {
        $episode = GetEpisodeNumber -Name $_.FileName;
        return $episode -notin $DownloadedEpisodes
    }
}

if ($links.Length -eq 0) {
    Write-Host "No New Episode Found. Exiting"
    timeout.exe 5;
}

$DownloadLinks = Multi-Options-Selector.ps1 -options $links;
if ($DownloadLinks.Count -eq 0) {
    return;
}

$DownloadLinks | ForEach-Object {
    Start-Process $_;
}

Set-Clipboard -Value ($DownloadLinks -join "`n")
timeout.exe 5;
