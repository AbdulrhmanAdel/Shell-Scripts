[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 1)]
    [string]
    $Title,
    [switch]
    $SkipDualAudio = $false
)

function GetLink {
    param (
        $Id
    )

    # {
    #     "success": true,
    #     "shortenedUrl": "https://ouo.io/ZfjmrQ",
    #     "shortener": "ouo.io",
    #     "cached": false
    # }
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Mobile Safari/537.36"
    $Result = Invoke-WebRequest -UseBasicParsing -Uri "https://anidl.org/api/secure-shorten" `
        -Method "POST" `
        -WebSession $session `
        -Headers @{
        "authority"                   = "anidl.org"
        "method"                      = "POST"
        "path"                        = "/api/secure-shorten"
        "scheme"                      = "https"
        "accept"                      = "*/*"
        "accept-encoding"             = "gzip, deflate, br, zstd"
        "accept-language"             = "en-US,en;q=0.9"
        "origin"                      = "https://anidl.org"
        "priority"                    = "u=1, i"
        "referer"                     = "https://anidl.org/on-going"
        "sec-ch-ua"                   = "`"Brave`";v=`"147`", `"Not.A/Brand`";v=`"8`", `"Chromium`";v=`"147`""
        "sec-ch-ua-arch"              = "`"`""
        "sec-ch-ua-bitness"           = "`"64`""
        "sec-ch-ua-full-version-list" = "`"Brave`";v=`"147.0.0.0`", `"Not.A/Brand`";v=`"8.0.0.0`", `"Chromium`";v=`"147.0.0.0`""
        "sec-ch-ua-mobile"            = "?1"
        "sec-ch-ua-model"             = "`"SM-G981B`""
        "sec-ch-ua-platform"          = "`"Android`""
        "sec-ch-ua-platform-version"  = "`"13`""
        "sec-fetch-dest"              = "empty"
        "sec-fetch-mode"              = "cors"
        "sec-fetch-site"              = "same-origin"
    } `
        -ContentType "application/json" `
        -Body "{`"fileId`":`"$Id`"}"
    
    $body = $Result.Content | ConvertFrom-Json;
    if ($body.success) {
        return $body.shortenedUrl;
    }
    else {
        throw "Failed to shorten link for fileId $Id";
    }
}

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
$Title = $Title + "+720P";
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Mobile Safari/537.36"
# $session.Cookies.Add((New-Object System.Net.Cookie("cf_clearance", "DFe2oqmI0m2enLsgz_qH_lTm.FvFqSvLCUO.HqMV4TY-1781620990-1.2.1.1-fZqqX55VmIsAngEWNVeYFFE1JSlljWPNtRHoaFGD5mw0O_SYp9zSH2sFmsepEC1fgLMEg4bLoOvm5noYqL7Knpam6kbeqKUuNM04R.WF9tKxg88GzObCNrFJ_sWAXHyByQKjOEKZ0Sz2ySh1AIpttze7lJQ07H45bRetVkRUoAOPngyIbt7dSr4G_38jMuFW13m0vOCTUnbAw2uSv35OT6oxiCES0NEI.2jO23tTCd3zQuxES1jpfogAAQs1TZNlp7WjqvEHCEk0q_ShYMZkb915grS_3.r9xc5_UhUABUYGJ_Opxz92n.tf4svYDP2QAH8UfkeD9I3qP4ts4s1MwQ", "/", ".anidl.org")))
$Result = Invoke-WebRequest -UseBasicParsing -Uri "https://anidl.org/api/on_air_data?page=1&limit=25&search=$Title&sortField=date&sortOrder=desc" `
    -WebSession $session `
    -Headers @{
    "authority"                   = "anidl.org"
    "method"                      = "GET"
    "path"                        = "/api/on_air_data?page=1&limit=25&search=$Title&sortField=date&sortOrder=desc"
    "scheme"                      = "https"
    "accept"                      = "*/*"
    "accept-encoding"             = "gzip, deflate, br, zstd"
    "accept-language"             = "en-US,en;q=0.9"
    "priority"                    = "u=1, i"
    "referer"                     = "https://anidl.org/on-going"
    "sec-ch-ua"                   = "`"Brave`";v=`"147`", `"Not.A/Brand`";v=`"8`", `"Chromium`";v=`"147`""
    "sec-ch-ua-arch"              = "`"`""
    "sec-ch-ua-bitness"           = "`"64`""
    "sec-ch-ua-full-version-list" = "`"Brave`";v=`"147.0.0.0`", `"Not.A/Brand`";v=`"8.0.0.0`", `"Chromium`";v=`"147.0.0.0`""
    "sec-ch-ua-mobile"            = "?1"
    "sec-ch-ua-model"             = "`"SM-G981B`""
    "sec-ch-ua-platform"          = "`"Android`""
    "sec-ch-ua-platform-version"  = "`"13`""
    "sec-fetch-dest"              = "empty"
    "sec-fetch-mode"              = "cors"
    "sec-fetch-site"              = "same-origin"
};
$responseBody = $Result.Content | ConvertFrom-Json;
$data = $responseBody.files;
if ($data.Length -eq 0) {
    Write-Host "No results found" -ForegroundColor Red;
    timeout.exe 5;
}

$links = $data  | Where-Object { $_.filename -match "720p" } | ForEach-Object {
    $fileName = $_.filename;
    $arabicSubsCount = $_.subtitle | `
        Where-Object { $_.lang -match "Arabic|ARA" -or $_.flag -match "fi-sa" } | `
        Measure-Object | Select-Object -ExpandProperty Count

    return @{
        Source       = $_
        Id           = $_.id
        FileName     = $fileName
        Audio        = $_.audio
        Size         = $_.size
        HasArabicSub = $arabicSubsCount -ge 1
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
    Exit;
}


$links = $links | Where-Object {
    if (!$SkipDualAudio) {
        return $true;
    }
    
    return $_.Audio.Count -eq 1
} | ForEach-Object {
    return @{
        Key   = $_.FileName;
        Value = $_
    }
}

$DownloadLinks = Multi-Options-Selector.ps1 -options $links;
if ($DownloadLinks.Count -eq 0) {
    return;
}

$DownloadLinks | ForEach-Object {
    $link = $null;
    $tries = 10;
    while (-not $link -or $tries -eq 0) {
        $temp = GetLink -Id $_.Id;
        if ($temp -match "https://ouo.io/") {
            $link = $temp;
        }
        else {
            $tries--;
            Write-Host "Generated shorten ($temp) is not supported retrying... left tries ($tries)" -ForegroundColor Red;
            Start-Sleep -Seconds 2;
        }
    }
    $_.Link = $link;
    Start-Process $link;
}

$DownloadLinks = $DownloadLinks | ForEach-Object {
    return $_.Link;
};
Set-Clipboard -Value ($DownloadLinks -join "`n")
timeout.exe 5;
