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
if (!$Title.EndsWith("720P")) {
    $Title += "+720P";
}




$Result = curl 'https://anidl.org/wp-admin/admin-ajax.php' `
    -H 'accept: application/json, text/javascript, */*; q=0.01' `
    -H 'accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ar;q=0.6,ru;q=0.5' `
    -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' `
    -H 'cookie: cf_clearance=JLJRJRJpJ_wOs3EMvJ097t_7v.rv_VAQYtoxKcGoTXc-1739151090-1.2.1.1-7EJC3k6EhIhHr5NL6epbatR9KH1RoP2locF32bMLmlPZWDpIo8ijIJMWNt2WSTKoQV0YeBJ8t_jkYL0fTxk1sxrWRbr3wxANAr9vFsg1b.cJNzIq3T3XsHgP16N0i.E8K7hbxZ1vVBRj.rZL7DbOodiJRx4c9no97cKnthLPHdkk1yZieqwdAe3wMbChRFKILbnf07cuV6WZjR0ZgHQ7eBig4MLnAPMCl_DChtdikHhf5Q4yj5HwPpAgjpVEkHqemGbIeR4D.A.1CfbnqJBgnLAMtyt6RQsxvqXg3CkCHrw' `
    -H 'dnt: 1' `
    -H 'origin: https://anidl.org' `
    -H 'priority: u=1, i' `
    -H 'referer: https://anidl.org/airing-anime/' `
    -H 'sec-ch-ua: "Not A(Brand";v="8", "Chromium";v="132", "Microsoft Edge";v="132"' `
    -H 'sec-ch-ua-mobile: ?0' `
    -H 'sec-ch-ua-platform: "Windows"' `
    -H 'sec-fetch-dest: empty' `
    -H 'sec-fetch-mode: cors' `
    -H 'sec-fetch-site: same-origin' `
    -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0' `
    -H 'x-requested-with: XMLHttpRequest' `
    --data-raw "draw=6&columns%5B0%5D%5Bdata%5D=tv_icon&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=false&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=filename&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=false&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B2%5D%5Bdata%5D=code&columns%5B2%5D%5Bname%5D=&columns%5B2%5D%5Bsearchable%5D=true&columns%5B2%5D%5Borderable%5D=false&columns%5B2%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B2%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B3%5D%5Bdata%5D=date&columns%5B3%5D%5Bname%5D=&columns%5B3%5D%5Bsearchable%5D=true&columns%5B3%5D%5Borderable%5D=false&columns%5B3%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B3%5D%5Bsearch%5D%5Bregex%5D=false&start=0&length=100&search%5Bvalue%5D=$Title&search%5Bregex%5D=false&action=get_mongodb_data";

$responseBody = $Result | ConvertFrom-Json;
$data = $responseBody.data;
if ($data.Length -eq 0) {
    Write-Host "No results found" -ForegroundColor Red;
    timeout.exe 5;
}

$links = $data | ForEach-Object {
    $fileName = $_.filename;
    $fileName -match "(?<Size>\d+ MBs)" | Out-Null;
    $hasArabicSub = $fileName.Contains("fi fi-sa");
    $size = $matches["Size"];
    $endIndex = $fileName.IndexOf(" <span");
    $fileName = $fileName.Substring(4, $endIndex - 4);
    $link = $_.code;
    $linkEndIndex = $link.IndexOf(""" ");
    $link = $link.Substring(9, $linkEndIndex - 9);
 
    # Write-Host $fileName -NoNewline -ForegroundColor Green;
    # Write-Host " => " -NoNewline -ForegroundColor Red;
    # Write-Host $link -ForegroundColor Yellow;
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
$DownloadLinks = Multi-Options-Selector.ps1 -options $links;
if ($DownloadLinks.Count -eq 0) {
    return;
}

$DownloadLinks | ForEach-Object {
    Start-Process $_;
}

Set-Clipboard -Value ($DownloadLinks -join "`n")
timeout.exe 5;
