[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Title
)

$Title = $Title.Trim() -replace " +", " " -replace " ", "+";
$Result = curl -sS "https://anidl.org/wp-admin/admin-ajax.php"  `
    -H "accept: application/json, text/javascript, */*; q=0.01"   `
    -H "accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ar;q=0.6"   `
    -H "content-type: application/x-www-form-urlencoded; charset=UTF-8"   `
    -H "dnt: 1"  `
    -H "origin: https://anidl.org"  `
    -H "priority: u=1, i"  `
    -H "referer: https://anidl.org/airing-anime/"  `
    -H "sec-ch-ua: \"Microsoft Edge\";v=\"131\", \"Chromium\";v=\"131\", \"Not_A Brand\";v=\"24\""  `
    -H "sec-ch-ua-mobile: ?1"  `
    -H "sec-ch-ua-platform: \"Android\""  `
    -H "sec-fetch-dest: empty"  `
    -H "sec-fetch-mode: cors"  `
    -H "sec-fetch-site: same-origin"  `
    -H "user-agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36 Edg/131.0.0.0"  `
    -H "x-requested-with: XMLHttpRequest"   `
    --data-raw "draw=6&columns%5B0%5D%5Bdata%5D=tv_icon&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=false&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=filename&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=false&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B2%5D%5Bdata%5D=code&columns%5B2%5D%5Bname%5D=&columns%5B2%5D%5Bsearchable%5D=true&columns%5B2%5D%5Borderable%5D=false&columns%5B2%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B2%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B3%5D%5Bdata%5D=date&columns%5B3%5D%5Bname%5D=&columns%5B3%5D%5Bsearchable%5D=true&columns%5B3%5D%5Borderable%5D=false&columns%5B3%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B3%5D%5Bsearch%5D%5Bregex%5D=false&start=0&length=100&search%5Bvalue%5D=$Title&search%5Bregex%5D=false&action=get_mongodb_data";

$Date = $Result | ConvertFrom-Json;
$Date.data | ForEach-Object {
    $fileName = $_.filename;
    $endIndex = $fileName.IndexOf(" <span");
    $fileName = $fileName.Substring(4, $endIndex - 4);
    $link = $_.code;
    $linkEndIndex = $link.IndexOf(""" ");
    $link = $link.Substring(9, $linkEndIndex - 9);

    Write-Host $fileName -NoNewline -ForegroundColor Green;
    Write-Host " => " -NoNewline -ForegroundColor Red;
    Write-Host $link -ForegroundColor Yellow;
};

