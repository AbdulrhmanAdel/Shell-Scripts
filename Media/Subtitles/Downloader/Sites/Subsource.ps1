. Parse-Args.ps1 $args;
$subsourceSiteDomain = "https://subsource.net";
$baseUrl = "https://api.subsource.net/api";
$global:subtitlePageLink = "";
Write-Host "Using Subsource API" -ForegroundColor Magenta;
Write-Host "==============================" -ForegroundColor Red;
Write-Host "Handling: " -ForegroundColor Green -NoNewline;
Write-Host "$name " -ForegroundColor DarkBlue -NoNewline;
Write-Host "Type: $type " -ForegroundColor Green -NoNewline;
if ($type -eq "S") {
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
    $searchResult = Invoke-Request -path "searchMovie" -body @{
        query = $name
    } -property "found";
    if ($searchResult.Length -eq 0) {
        Start-Process "$subsourceSiteDomain/search/$name"
        EXIT;
    }
    $subsourceType = $type -eq "S" ? "TVSeries": "Movie";
    $matchShows = @($searchResult | Where-Object {
            $isTheSameType = $_.type -eq $subsourceType -and $_.title -eq $name; ;
                
            return !!$Year `
                ? $isTheSameType -and $_.releaseYear -eq $Year `
                : $isTheSameType;
        })

    $movieInfo = $null;
    if ($matchShows.Length -gt 1 -and !$year) {
        $matchShows | ForEach-Object {
            Write-Host "$($_.title) -> $($_.releaseYear)"
        }
        $year = Read-Host "Multi matched Shows please enter correct Year";
        $movieInfo = $matchShows | Where-Object {
            return $_.releaseYear -eq $year
        } | Select-Object -First 1
    }
    elseif ($matchShows.Length -eq 1) {
        $movieInfo = $matchShows[0]
    }
    else {
        $movieInfo = $searchResult[0]
    }

    $movieInfo = $movieInfo ?? $searchResult[0];
    $global:subtitlePageLink = "$subsourceSiteDomain/subtitles/$( $movieInfo.linkName )"
    $body = @{
        langs     = @("Arabic")
        movieName = $movieInfo.linkName
    };
    if ($season -and $type -eq "S") {
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
    Write-Host "Downloading Subtitle From => $subsourceSiteDomain/$( $sub.fullLink )" -ForegroundColor Blue;
    Write-Host "Release Name $($sub.releaseName)" -ForegroundColor Blue;
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

if ($type -eq "M") {
    $matchedSubtitle = $arabicSubs | Where-Object {
        $_.releaseName -match $Quality
    } | Select-Object -First 1;

    if (!$matchedSubtitle) {
        Write-Host "No Matching Subtitle For $name with Qualtiy $Quality, Picking First Available One" -ForegroundColor Red;
        $matchedSubtitle = $arabicSubs[0];
    }

    $subtitlePath = DownloadSubtitle -sub $matchedSubtitle;
    CopySubtitle -subtitlePath  $subtitlePath `
        -savePath $savePath `
        -renameTO $renameTo `
        -qualityRegex $Quality;

    Exit;
}

$wholeSeasonRegex = "(S0$season)([^EX0-9]|$)|" +
"(S0$season)(\.| \[)?(1080P|720P|480P)|" +
"(S0$season)E\d\d*(>|~)E\d\d*";

$wholeSeasonSubtitles = @(
    $arabicSubs | Where-Object {
        return $_.releaseName -replace "\.| ", "" -match $wholeSeasonRegex `
            -or $_.commentary -contains "الموسم كامل" `
            -or $_releaseName -match "Complete(\.| )?Season"
    }
);

$Episodes | ForEach-Object {
    Write-Host "-----" -ForegroundColor Yellow;
    $episode = $_;
    $episodeNumber = $episode.Episode;
    $episodeRegex = "(S?0*$season)?(\.| )*(E|\d+X|Episode|EP)0*$episodeNumber(\D+|$)";
    $qualityRegex = "$( $episode.Quality )"
    Write-Host "Episode $episodeNumber" -ForegroundColor Yellow;
    $firstMatchedSubtitle = $null;
    $qualityMatchedSubtitle = $null;
    foreach ($arabicSub in $arabicSubs) {
        if ($arabicSub.releaseName -match $episodeRegex) {
            if (!$firstMatchedSubtitle) {
                $firstMatchedSubtitle = $arabicSub;
            }

            if ($arabicSub.releaseName -match $qualityRegex) {
                Write-Host "FOUND EXACT Quality => $( $arabicSub.releaseName )" -ForegroundColor Cyan;
                $qualityMatchedSubtitle = $arabicSub;
                break;
            }
        }
    }

    if (!$qualityMatchedSubtitle -and $wholeSeasonSubtitles.Length -gt 0) {
        $qualityMatchedSubtitle = $wholeSeasonSubtitles | Where-Object {
            return $_.releaseName -match $qualityRegex;
        } | Select-Object -First 1;

        if (!$qualityMatchedSubtitle -and !$firstMatchedSubtitle) {
            $qualityMatchedSubtitle = $wholeSeasonSubtitles[0];
        }
    }

    if (!$qualityMatchedSubtitle) {
        $qualityMatchedSubtitle = $firstMatchedSubtitle;
    }

    if (!$qualityMatchedSubtitle) {
        Write-Host "CAN'T FIND Subtitle FOR $name => EPISODE $episodeNumber " -ForegroundColor Red -NoNewLine;
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
}

Write-Host "==============================" -ForegroundColor Red;