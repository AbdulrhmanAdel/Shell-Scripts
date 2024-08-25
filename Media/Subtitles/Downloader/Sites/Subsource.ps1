$subsourceSiteDomain = "https://subsource.net";

$global:subtitlePageLink = "";

Write-Host "Using Subsource API" -ForegroundColor Magenta;
$baseUrl = "https://api.subsource.net/api";
. Parse-Args.ps1 $args;

Write-Host "==============================" -ForegroundColor Red;
Write-Host "Handling: " -ForegroundColor Green -NoNewline;
Write-Host "$name " -ForegroundColor DarkBlue -NoNewline;
Write-Host "Type: $type" -ForegroundColor Green -NoNewline;
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
        
        if (!$reponse.Headers.TryGetValues("RateLimit-Remaining", [ref] $remainging)) {
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
    $movieInfo = $searchResult | Where-Object {
        $_.type -eq $subsourceType
    } | Select-Object -First 1;
    $movieInfo ??= $searchResult[0];
    
    $global:subtitlePageLink = "$subsourceSiteDomain/subtitles/$($movieInfo.linkName)"

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


$downloadSubtitleCache = @{};
function DownloadSubtitle {
    param (
        $sub
    )

    
    Write-Host "Downloading Subtitle From => $subsourceSiteDomain/$($matchedSubtitle.fullLink)" -ForegroundColor Blue;
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
    $tempPath = "$downloadPath/$($downloadSubDetails.fileName)";
    Invoke-WebRequest -Uri $downloadLink -OutFile $tempPath;
    $extractLocation = "$downloadPath\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
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

    $files = @(Get-ChildItem -LiteralPath $subtitlePath -Include *.ass, *.srt);
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

        Copy-Item -LiteralPath $file.FullName `
            -Destination "$savePath/$($finalName)$($file.Extension)";
    }
}

#endregion

$subtitles = GetSubtitles;
$arabicSubs = $subtitles | Where-Object {
    return $_.lang -eq "Arabic" 
}

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

$wholeSeasonRegex = "(S0*$season)[^EX0-9]\D+"
$wholeSeasonSubtitles = @(
    $arabicSubs | Where-Object {
        return $_.releaseName -match $wholeSeasonRegex
    }
);

$Episodes | ForEach-Object {
    $episode = $_;
    $episodeNumber = $episode.Episode;
    $qualityRegex = "$($episode.Quality)"
    $episodeRegex = "(S?0*$season)(E|X)0*$($episodeNumber)\D*$";
    $matchedSubtitle = $null;
    Write-Host "-----" -ForegroundColor Yellow;
    Write-Host "Episode $episodeNumber" -ForegroundColor Yellow;

    foreach ($arabicSub in $arabicSubs) {
        if ($arabicSub.releaseName -match $episodeRegex) {
            if (!$matchedSubtitle) {
                $matchedSubtitle = $arabicSub;
            }

            if ($arabicSub.releaseName -match $qualityRegex) {
                Write-Host "FOUND EXACT Quality => $($arabicSub.releaseName)" -ForegroundColor Cyan;
                $matchedSubtitle = $arabicSub;
                break;
            }
        }
    }

    if (!$matchedSubtitle) {
        $matchedWholeSeasonSubtitles = $wholeSeasonSubtitles | Where-Object {
            return $_.releaseName -match $qualityRegex;
        } | Select-Object -First 1;
    
        if (!$matchedWholeSeasonSubtitles) {
            Write-Host "CAN'T FIND Subtitle FOR $name => EPISODE $episodeNumber " -ForegroundColor Red -NoNewLine;
            Write-Host "$global:subtitlePageLink" -ForegroundColor Blue;
            return;
        }
        $matchedSubtitle = $matchedWholeSeasonSubtitles;
    }
 
    $subtitlePath = DownloadSubtitle -sub  $matchedSubtitle;
    CopySubtitle -subtitlePath  $subtitlePath `
        -savePath $episode.SavePath `
        -renameTO $episode.RenameTo `
        -episodeRegex $episodeRegex `
        -qualityRegex "$qualityRegex";
}

Write-Host "==============================" -ForegroundColor Red;