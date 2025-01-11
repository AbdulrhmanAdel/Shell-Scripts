. Parse-Args.ps1 $args;
$subsourceSiteDomain = "https://subsource.net";
$baseUrl = "https://api.subsource.net/api";
$global:subtitlePageLink = "";
Write-Host "Using Subsource API" -ForegroundColor Magenta;
Write-Host "==============================" -ForegroundColor Red;
Write-Host "Handling: " -ForegroundColor Green -NoNewline;
Write-Host "$title " -ForegroundColor DarkBlue -NoNewline;
Write-Host "Type: $type " -ForegroundColor Green -NoNewline;
if ($type -eq "Series") {
    Write-Host "Season: $season; " -ForegroundColor Green -NoNewline;
    Write-Host "Episodes: " -ForegroundColor Green -NoNewline;
    Write-Host ($Episodes | ForEach-Object { return $_.Episode }) -Separator ", " -ForegroundColor Green;
}
else {
    Write-Host ""
}

#region Functions
function Invoke-Request {
    param (
        $path,
        $body,
        $property
    )
    try {
        $url = "$baseUrl/$path";
        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0"
        $session.Cookies.Add((New-Object System.Net.Cookie("connect.sid", "s%3AJjQvrc15KYCTzhj3clCJLqSJfZJSulSN.89cjTrabd1I%2F4Ir%2Bh7GkTY8tvgm%2FNotqwNOU3IITq7w", "/", "api.subsource.net")))
        $session.Cookies.Add((New-Object System.Net.Cookie("cf_clearance", "ivfeWZCYBe2u6yrtSRaLJIExqrUjeVimUtvC.XiKUsw-1736529721-1.2.1.1-vMPWP9QH6DDm9pLsFY_sFoU0zxQow7RG2cJYJoq3XPcdzJi9kJzN4jYNmexXN2Z8joUm6B0mS70AXzrEVsVWwhxyb3cA8kgdIcpZ6NSTvvsSGGFB.rT0sJrFGIwUS9p8ZoPDKHzLda6k1CQCq498kyON_fb27vcOjR_vrdfm1NSowqh9QCIavAHB8TUq41xGn9yhSMzDPrQrBv4GlawXZo6AtxF2aNcmOojyeQzsuG.z.A3nfKffiqHEQNn1Oe13D9ZV_18aPHx_bH05Dc_dY.l1AZw21l0VTf7UscjMIl6lzF2OYkmbTebUQDgbV9Sg.Y6ClfdPsqSMEFkrU0Lk.vBHKlc79kfDF1aubhc_JOjaXDIkStnXPv057WU.P7ObJXJ1lWIoJ44ibGCexPsxwQ", "/", ".subsource.net")))
        $result = Invoke-WebRequest -Uri  $url `
            -Method "POST" `
            -WebSession $session `
            -Headers @{
            "accept"             = "application/json, text/plain, */*"
            "accept-encoding"    = "gzip, deflate, br, zstd"
            "accept-language"    = "en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ar;q=0.6"
            "dnt"                = "1"
            "origin"             = "https://subsource.net"
            "priority"           = "u=1, i"
            "referer"            = "https://subsource.net/"
            "sec-ch-ua"          = "`"Microsoft Edge`";v=`"131`", `"Chromium`";v=`"131`", `"Not_A Brand`";v=`"24`""
            "sec-ch-ua-mobile"   = "?0"
            "sec-ch-ua-platform" = "`"Windows`""
            "sec-fetch-dest"     = "empty"
            "sec-fetch-mode"     = "cors"
            "sec-fetch-site"     = "same-site"
        } `
            -ContentType "application/json" `
            -Body $body
        
        $content = $result.Content | ConvertFrom-Json;
        if ($property) {
            return $content.$property;
        }
        return $content;
    }
    catch {
        $reponse = $_.Exception.Response;
        $_.Exception.Response.Content | Out-String;
        if ($reponse.StatusCode -ne 429) {
            return;
        }
        $remainging = $null;
        if (!$reponse.Headers.TryGetValues("RateLimit-Remaining", [ref]$remainging)) {
            return;
        }
        $remainging = [Int32]::Parse($remainging) * 2;
        Write-Host "⚠️ RateLimit Hitted Waiting For $remainging MS ⚠️" -ForegroundColor Black -BackgroundColor Red;
        Start-Sleep -Milliseconds $remainging;
        return Invoke-Request `
            -path $path `
            -body $body `
            -propert $property;
    }
}

function GetSubtitles {
    $show = & Imdb-GetShow.ps1 -Name $title -Type $type -Year $Year;
    # $show = $null;
    $searchQuery = (!!$show ? $show.id : $null) ?? (!$Year ? $title : $title + " " + $Year);
    $queryBody = @{
        query = $searchQuery
    };
    
    $searchResult = @(Invoke-Request -path "searchMovie" -body $queryBody -property "found");
    if ($searchResult.Length -eq 0) {
        Start-Process "$subsourceSiteDomain/search/$title"
        EXIT;
    }

    $movieInfo = $searchResult[0];
    if (!$show) {
        $subsourceType = $type -eq "Series" ? "TVSeries": "Movie";
        $sameTypeShows = @($searchResult | Where-Object { $_.type -eq $subsourceType });
        if ($sameTypeShows.Length -gt 1) {
            $year ??= Read-Host "Multi matched Shows please enter correct Year";
            $sameYearsShows = @(
                $sameTypeShows | Where-Object {
                    $_.releaseYear -eq $Year
                }
            );

            $exactTitleShow = $sameTypeShows | Where-Object {
                $_.title -eq $title
            }  | Select-Object -First 1;

            if ($exactTitleShow) {
                $movieInfo = $exactTitleShow;
            } 
            elseif ($sameTypeShows.Length -gt 1) {
                Write-Host "There is multi shows with the same year and name"
                $script:index = 0;
                $sameTypeShows | ForEach-Object {
                    Write-Host "$($script:index + 1) " -ForegroundColor Green -NoNewline;
                    Write-Host "$($_.title)" -ForegroundColor Green;
                    $script:index++;
                }

                $chosedIndex = (Read-Host "Please Pick one with the number") - 1;
                $movieInfo = $sameYearsShows[$chosedIndex];
            }
            else {
                $movieInfo = $sameYearsShows[0];
            }
        }
        $movieInfo = $movieInfo ?? $sameTypeShows[0];
    }
    $global:subtitlePageLink = "$subsourceSiteDomain/subtitles/$( $movieInfo.linkName )"
    $body = @{
        langs     = @("Arabic")
        movieName = $movieInfo.linkName
    };
    if ($season -and $type -eq "Series") {
        $body["season"] = "season-$season";
        $global:subtitlePageLink += "/season-$season"
    }
    Write-Host "Subtitle Page $global:subtitlePageLink" -ForegroundColor Green;
    return Invoke-Request -path "getMovie" -Body $body -property "subs";
}

$downloadSubtitleCache = @{ };
function DownloadSubtitle {
    param (
        $sub
    )
    Write-Host "Downloading Subtitle From => "  -NoNewLine;
    Write-Host "$subsourceSiteDomain$($sub.fullLink)" -ForegroundColor Blue;
    Write-Host "Release Name " -NoNewLine;
    Write-Host "$($sub.releaseName)" -ForegroundColor Blue;
    if ($downloadSubtitleCache[$sub.subId]) {
        return $downloadSubtitleCache[$sub.subId];
    }
    $downloadSubDetails = Invoke-Request -path "getSub" -Body @{
        movie = $sub.linkName
        lang  = $sub.lang
        id    = $sub.subId
    } -property "sub";
    $downloadToken = $downloadSubDetails.downloadToken;
    $downloadLink = "$baseUrl/downloadSub/$downloadToken";
    $tempPath = "$downloadPath/$( $downloadSubDetails.fileName )";
    Invoke-WebRequest -Uri $downloadLink -OutFile $tempPath;
    $extractLocation = "$downloadPath\$( Get-Date -Format 'yyyy-MM-dd-HH-mm-ss' )"
    & 7z.exe  x $tempPath -aoa -bb0 -o"$extractLocation" | Out-Null;
    $downloadSubtitleCache[$sub.subId] = $extractLocation;
    Start-Sleep -Milliseconds 500;
    return $extractLocation;
}


function CopySubtitle {
    param (
        $subtitlePath,
        $details,
        $savePath,
        $renameTo,
        $episodeRegex,
        $qualityRegex
    )
    
    $files = @(Get-ChildItem -LiteralPath $subtitlePath -Force -Include *.ass, *.srt, *.sub);
    $fileIndex = 0;

    if ($episodeRegex -and $files.Length -gt 1) {
        $files = @($files | Where-Object { $_.Name -match $episodeRegex })
    }

    if ($qualityRegex -and $files.Length -gt 1) {
        $primaryFile = $files | Where-Object { $_.Name -match $qualityRegex } | Select-Object -First 1;
        if ($primaryFile) {
            $files = @($primaryFile);
        }
    }

    $files | ForEach-Object {
        $file = $files[$fileIndex];
        $finalName = $file.Name -replace $file.Extension, "";
        if ($renameTo) {
            $finalName = $renameTo;
        }
        if ($files.Length -gt 1) {
            if ($fileIndex -gt 0) {
                $finalName += ".$fileIndex"
            }
            $fileIndex++;
        }

        if ( $file.Attributes.HasFlag([System.IO.FileAttributes]::Hidden)) {
            $file.Attributes -= "Hidden";
        }

        Copy-Item -LiteralPath $file.FullName `
            -Destination "$savePath/$( $finalName )$( $file.Extension )";
    }
}

#endregion
function MatchRelease {
    param (
        [string]$releaseName,
        [string]$qualityRegex,
        [string[]]$ignoredVersions,
        [string[]]$keywords
    )

    # Check if release matches quality regex
    if ($releaseName -notmatch $qualityRegex) {
        return $false
    }

    # Check if any keyword matches
    if ($keywords.Length -gt 0) {

        $keywordMatched = $keywords | Where-Object { $releaseName -match $_ }
        if ($keywordMatched) {
            return $true
        }
    }

    # Check if version is ignored
    $isIgnoredVersion = $ignoredVersions | Where-Object { $releaseName -match $_ }
    return -not $isIgnoredVersion
}

$arabicSubs = GetSubtitles | Where-Object {
    return $_.lang -eq "Arabic"
};

if ($type -eq "Movie") {
    $matchedSubtitle = $arabicSubs | Where-Object { 
        MatchRelease -releaseName $_.releaseName `
            -qualityRegex $Quality `
            -ignoredVersions $IgnoredVersions `
            -keywords $Keywords;
    } | Select-Object -First  1;
    $matchedSubtitle ??= $arabicSubs[0];
    $subtitlePath = DownloadSubtitle -sub $matchedSubtitle
    CopySubtitle -subtitlePath $subtitlePath -savePath $savePath -renameTo $renameTo -qualityRegex $Quality
    return
}

$wholeSeasonRegex = "(S0$season)([^EX0-9]|$)|" + `
    "(S0$season)(\.| \[)?(1080P|720P|480P)|" + `
    "(S0$season)E\d\d*(>|~)E\d\d*";
$wholeSeasonSubtitles = @(
    $arabicSubs | Where-Object {
        return $_.releaseName -replace "\.| ", "" -match $wholeSeasonRegex `
            -or $_.commentary -contains "الموسم كامل" `
            -or $_releaseName -match "Complete(\.| )?Season"
    }
);

$arabicSubs = $arabicSubs | Where-Object { $_ -notin $wholeSeasonSubtitles };

$Episodes | ForEach-Object {
    $episode = $_;
    Write-Host "-----" -ForegroundColor Yellow;
    Write-Host "Episode $($episode.Episode)" -ForegroundColor Yellow;
    $episodeNumber = $episode.Episode;
    $qualityRegex = $episode.Quality
    $episodeRegex = "(S?0*$season)?(\.| )*(E|\d+X|Episode|EP)0*$episodeNumber(\D+|$)"
    $episodeSubtitles = @($arabicSubs | Where-Object { $_.releaseName -match $episodeRegex });
    $matchedSubtitle = $episodeSubtitles | Where-Object { 
        MatchRelease -releaseName $_.releaseName`
            -qualityRegex $qualityRegex `
            -ignoredVersions $episode.IgnoredVersions `
            -keywords $episode.Keywords; 
    } | Select-Object -First 1;

    if (!$matchedSubtitle) {
        $matchedSubtitle = $wholeSeasonSubtitles | Where-Object { 
            MatchRelease -releaseName $_.releaseName`
                -qualityRegex $qualityRegex `
                -ignoredVersions $episode.IgnoredVersions `
                -keywords $episode.Keywords; 
        } | Select-Object -First 1;
    }

    $matchedSubtitle ??= $episodeSubtitles[0];
    if (!$matchedSubtitle) {
        Write-Host "CAN'T FIND Subtitle FOR $title => EPISODE $episodeNumber " -ForegroundColor Red -NoNewLine;
        Write-Host "$global:subtitlePageLink" -ForegroundColor Blue;
        
        [Console]::Beep(1000, 500);
        return;
    }

    $subtitlePath = DownloadSubtitle -sub $matchedSubtitle;
    CopySubtitle -subtitlePath  $subtitlePath `
        -savePath $episode.SavePath `
        -renameTO $episode.RenameTo `
        -episodeRegex $episodeRegex `
        -qualityRegex $qualityRegex;
}

Write-Host "==============================" -ForegroundColor Red;