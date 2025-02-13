[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Links
)

function GetDownloadLink {
    param (
        [string]$Link
    )

    $url = [uri]$Link;
    $segments = $url.PathAndQuery.Split('/');
    $fileName = $segments[-1];
    $fileCode = $segments[-2];
    $Request = curl 'https://datanodes.to/download' `
        -H 'accept: */*' `
        -H 'accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ar;q=0.6,ru;q=0.5' `
        -b "file_code=$fileCode; file_name=$fileName; lang=english;" `
        -H 'dnt: 1' `
        -H 'origin: https://datanodes.to' `
        -H 'priority: u=1, i' `
        -H 'referer: https://datanodes.to/download' `
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0' `
        -F "op=download2" `
        -F "id=$fileCode" `
        -F "rand=" `
        -F "referer=https://datanodes.to/download" `
        -F "method_free=Free Download >>" `
        -F "method_premium=" `
        -F "dl=1";
        
    $response = $Request | ConvertFrom-Json;
    $url = [System.Web.HttpUtility]::UrlDecode($response.url);
    return $url;
}

if ($Links.Length -eq 0) {
    $Result = Read-Host "There are no links provided, Please Provide links separated by space";
    $Links = $Result.Split(" ");
}

$Links = $Links | ForEach-Object {
    return GetDownloadLink -Link $_;
};

Set-Clipboard $Links;
Write-Host "Links Copied To Clipboard";
timeout.exe 15;