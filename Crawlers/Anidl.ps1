[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 1)]
    [string]
    $Title
)

if (Test-Path -LiteralPath $Title) {
    $Title = Split-Path -Path $Title -Leaf
}

Write-Host "Searching for $Title" -ForegroundColor Green;
$Title = $Title.Trim() -replace "-", " " -replace " +", " " -replace " ", "+";
if (!$Title.EndsWith("720P")) {
    $Title += "+720P";
}

$Result = curl --progress-bar "https://anidl.org/wp-admin/admin-ajax.php"  `
    --data-raw "draw=6&columns%5B0%5D%5Bdata%5D=tv_icon&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=false&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=filename&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=false&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B2%5D%5Bdata%5D=code&columns%5B2%5D%5Bname%5D=&columns%5B2%5D%5Bsearchable%5D=true&columns%5B2%5D%5Borderable%5D=false&columns%5B2%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B2%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B3%5D%5Bdata%5D=date&columns%5B3%5D%5Bname%5D=&columns%5B3%5D%5Bsearchable%5D=true&columns%5B3%5D%5Borderable%5D=false&columns%5B3%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B3%5D%5Bsearch%5D%5Bregex%5D=false&start=0&length=100&search%5Bvalue%5D=$Title&search%5Bregex%5D=false&action=get_mongodb_data";

$responseBody = $Result | ConvertFrom-Json;
$data = $responseBody.data;
if ($data.Length -eq 0) {
    Write-Host "No results found" -ForegroundColor Red;
    timeout.exe 5;
}

$links = $data | ForEach-Object {
    $fileName = $_.filename;
    $endIndex = $fileName.IndexOf(" <span");
    $fileName = $fileName.Substring(4, $endIndex - 4);
    $link = $_.code;
    $linkEndIndex = $link.IndexOf(""" ");
    $link = $link.Substring(9, $linkEndIndex - 9);
    # Write-Host $fileName -NoNewline -ForegroundColor Green;
    # Write-Host " => " -NoNewline -ForegroundColor Red;
    # Write-Host $link -ForegroundColor Yellow;
    return @{
        Key   = $fileName;
        Value = $link -replace "#038;", "";
    }
};

$DownloadLinks = Multi-Options-Selector.ps1 -options $links;
if ($DownloadLinks.Count -eq 0) {
    return;
}

$DownloadLinks | ForEach-Object {
    Start-Process $_;
}

Set-Clipboard -Value ($DownloadLinks -join "`n")
timeout.exe 5;
