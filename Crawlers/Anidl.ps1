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
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36"
    $session.Cookies.Add((New-Object System.Net.Cookie("cf_clearance", "RDkCEtI9HyNTuG.H2w9IVizygGsW3Q5_V7oOiS37LSU-1791878899-1.2.1.1-hfAyN1on.1aXCzh4UFxrDeqZHf7frlvyLZLS7nwXk9c4WKOyjFm1Qz5YvBFeBFj6P6_rgyE2KuKw5Cxjgw2pry8yt49TwxWMKWTWFk36bmMz6owheyj9cmJbnRdM63hFBKxGdyS0nF8zI.RbCthW2wo8WYoKPnxq26cSTNY_Ng3AgWl6WK2KDOLJRj1auIJ2kMpVGGI_.AQQFtNh8jMNLnWb0kIHK8eP.5FNvluDBrZj3S7uAdTgbtzQz8iJeg26BualB0Rj22a2uyZYsIQdM6FWVPMYm2PR60H2If3PIKnywjmxYlQJRP7OCUuv.TGikHlyrGDgKCiQUFtDbUB9sMRDgRhBv7ogmZTj86A6dgk", "/", ".anidl.org")))
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
        "dnt"                         = "1"
        "origin"                      = "https://anidl.org"
        "priority"                    = "u=1, i"
        "referer"                     = "https://anidl.org/on-going"
        "sec-ch-ua"                   = "`"Brave`";v=`"155`", `"Chromium`";v=`"155`", `"Not(A:Brand`";v=`"24`""
        "sec-ch-ua-arch"              = "`"x86`""
        "sec-ch-ua-bitness"           = "`"64`""
        "sec-ch-ua-full-version-list" = "`"Brave`";v=`"155.0.0.0`", `"Chromium`";v=`"155.0.0.0`", `"Not(A:Brand`";v=`"24.0.0.0`""
        "sec-ch-ua-mobile"            = "?0"
        "sec-ch-ua-model"             = "`"`""
        "sec-ch-ua-platform"          = "`"Windows`""
        "sec-ch-ua-platform-version"  = "`"19.0.0`""
        "sec-fetch-dest"              = "empty"
        "sec-fetch-mode"              = "cors"
        "sec-fetch-site"              = "same-origin"
        "sec-gpc"                     = "1"
    } `
        -ContentType "application/json" `
        -Body "{`"fileId`":`"$Id`",`"preferredShortener`":`"ouo.io`"}"
    
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
        Key   = "$($_.FileName) [$($_.Size)] $($_.HasArabicSub ? '[Ar]' : '')";
        Value = $_
    }
}

$DownloadLinks = Multi-Options-Selector.ps1 -options $links;
if ($DownloadLinks.Count -eq 0) {
    return;
}

$supportedShortens = @(
    "https://ouo.io/"
    # "tpi.li"
);

$DownloadLinks | ForEach-Object {
    $link = $null;
    $tries = 10;
    $sleepInSeconds = 1;
    while ($tries -ge 0) {
        $temp = GetLink -Id $_.Id;
        $isSupportedShorten = @($supportedShortens | Where-Object {$temp -match  $_}).Count -ge 1;
        if ($isSupportedShorten -or $tries -eq 0) {
            $link = $temp;
            break;
        }
        else {
            $tries--;
            Write-Host "Generated shorten ($temp) is not supported retrying... left tries ($tries)" -ForegroundColor Red;
            Start-Sleep -Seconds $sleepInSeconds;
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
