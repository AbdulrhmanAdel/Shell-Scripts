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
        $result = Invoke-WebRequest -Uri $url -Body $body -Method Post
        $content = $result.Content | ConvertFrom-Json;
        if ($property) {
            return $content.$property;
        }
        return $content;
    }
    catch {
        $reponse = $_.Exception.Response;
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
    $show = & "Imdb-Get-Show.ps1" -Name $title -Type $type -Year $Year;
    $searchQuery = (!!$show ? $show.id : $null) ?? (!$Year ? $title : $title + " " + $Year);
    $queryBody = @{
        query = $searchQuery
    };
    
    $searchResult = @(Invoke-Request -path "searchMovie" -body $queryBody -property "found");
    if ($searchResult.Length -eq 0) {
        Start-Process "$subsourceSiteDomain/search/$title"
        EXIT;
    }

    $movieInfo = $null;

    if ($searchResult.Length -gt 1) {
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
    $movieInfo ??= $searchResult[0];
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
    Write-Host "$subsourceSiteDomain/$( $sub.fullLink )" -ForegroundColor Blue;
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

function MatchRelease {
    param (
        [string]$releaseName,
        [string]$qualityRegex,
        [string[]]$ignoredVersions,
        [string[]]$keywords
    )

    $isQualityMatched = $releaseName -match $qualityRegex;
    if (!$isQualityMatched) { return $false }
    $keywordMatched = $keywords.Length -gt 0 -and @($keywords | Where-Object { $releaseName -match $_ }).Length -gt 0;
    if ($keywordMatched) { return $true }
    $isIgnoredVersion = $ignoredVersions.Length -gt 0 -and @($ignoredVersions | Where-Object { $releaseName -match $_ }).Length -gt 0;
    return !$isIgnoredVersion;
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
            $finalName += ".$fileIndex"
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

$subtitles = GetSubtitles;
$arabicSubs = $subtitles | Where-Object {
    return $_.lang -eq "Arabic"
};

if ($type -eq "Movie") {
    $sameQualitySubtitles = @($arabicSubs | Where-Object { $_.releaseName -match $Quality });
    # $sameKeywords = $sameQualitySubtitle | Where-Object { $_.releaseName -match $Quality };
    $matchedSubtitle = (
        $sameQualitySubtitle | Where-Object {
            $_.releaseName -match $Quality
            return MatchRelease -releaseName $_.releaseName `
                -qualityRegex $Quality `
                -ignoredVersions $ignoredVersions `
                -keywords $keywords;
        } | Select-Object -First 1
    ) ?? $sameQualitySubtitles[0] ?? $arabicSubs[0];
    $subtitlePath = DownloadSubtitle -sub $matchedSubtitle;
    CopySubtitle -subtitlePath  $subtitlePath `
        -savePath $savePath `
        -renameTO $renameTo `
        -qualityRegex $Quality;
    Exit;
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
    Write-Host "-----" -ForegroundColor Yellow;
    Write-Host "Episode $($episode.Episode)" -ForegroundColor Yellow;
    $episode = $_;
    $episodeNumber = $episode.Episode;
    $episodeRegex = "(S?0*$season)?(\.| )*(E|\d+X|Episode|EP)0*$episodeNumber(\D+|$)";
    $qualityRegex = $episode.Quality
    $episodeSubtitles = @($arabicSubs | Where-Object { $_.releaseName -match $episodeRegex });
    $qualitySubtitles = @($arabicSubs | Where-Object { $_.releaseName -match $qualityRegex });
    $matchedSubtitle = $qualitySubtitles | Where-Object { 
        MatchRelease -releaseName $arabicSub.releaseName`
            -qualityRegex $qualityRegex `
            -ignoredVersions $episode.IgnoredVersions `
            -keywords $episode.Keywords; } | Select-Object -First 1;

    if (!$matchedSubtitle) {
        $matchedSubtitle = $wholeSeasonSubtitles | Where-Object { 
            MatchRelease -releaseName $arabicSub.releaseName`
                -qualityRegex $qualityRegex `
                -ignoredVersions $episode.IgnoredVersions `
                -keywords $episode.Keywords; } | Select-Object -First 1;
    }

    if (!$matchedSubtitle) {
        $matchedSubtitle = $
    }

    if (!$matchedSubtitle) {
        Write-Host "CAN'T FIND Subtitle FOR $title => EPISODE $episodeNumber " -ForegroundColor Red -NoNewLine;
        Write-Host "$global:subtitlePageLink" -ForegroundColor Blue;
        
        [Console]::Beep(1000, 500);
        return;
    }

    $subtitlePath = DownloadSubtitle -sub $qualityMatchedSubtitle;
    CopySubtitle -subtitlePath  $subtitlePath `
        -savePath $episode.SavePath `
        -renameTO $episode.RenameTo `
        -episodeRegex $episodeRegex `
        -qualityRegex "$qualityRegex";

    $arabicSubs = $arabicSubs | Where-Object { $_ -notin $episodeSubtitles };
}

Write-Host "==============================" -ForegroundColor Red;