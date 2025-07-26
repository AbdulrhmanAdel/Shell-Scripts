[CmdletBinding()]
param (
    [string]$DownloadPath,
    [string]$Type,
    [string]$Title,
    [string]$Quality,
    [string]$SavePath,
    [string]$RenameTo,
    [int]$Year,
    [string[]]$IgnoredVersions,
    [string[]]$Keywords,
    [int]$Season,
    [string]$ShowImdbId,
    [System.Object[]]$Episodes
)

$downloaderScriptPath = Resolve-Path "$PSScriptRoot\..\Helpers\Downloader.ps1";
$subsourceSiteDomain = "https://subsource.net";
$baseUrl = "https://api.subsource.net/v1";
$global:subtitlePageLink = "";
Write-Host "Using Subsource API" -ForegroundColor Magenta;
Write-Host "==============================" -ForegroundColor Red;
Write-Host "Handling: " -ForegroundColor Green -NoNewline;
Write-Host "$title " -ForegroundColor DarkBlue -NoNewline;
Write-Host "Type: $type " -ForegroundColor Green -NoNewline;
if ($type -eq "Series") {
    Write-Host "Season: $season; " -ForegroundColor Green -NoNewline;
    Write-Host "Episodes: " -ForegroundColor Green -NoNewline;
    Write-Host ($Episodes | ForEach-Object { return $_.Episode }) -Separator ", " -ForegroundColor Green -NoNewline;
}
Write-Host ""

#region Functions
function Invoke-Request {
    param (
        $Path,
        $Body,
        $property
    )
    try {

        Write-Host "Invoking $Path" -ForegroundColor Yellow;
        if ($Body) {
            $Body = ($Body | ConvertTo-Json -Depth 100 -Compress)
            $data = curl --progress-bar "$baseUrl/$Path" `
                -H "accept: application/json, text/plain, */*"  `
                -H "accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ar;q=0.6"  `
                -H "content-type: application/json"  `
                --data-raw $Body;
        }
        else {
            $data = curl --progress-bar "$baseUrl/$Path" `
                -H "accept: application/json, text/plain, */*"  `
                -H "accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ar;q=0.6"  `
                -H "content-type: application/json"  `
        }

        $content = $data | ConvertFrom-Json;
        if ($property) {
            return $content.$property;
        }
        return $content;
    }
    catch {
        $response = $_.Exception.Response;
        if ($response.StatusCode -ne 429) {
            Write-Host "$($response.StatusCode) - $($_.Exception.Message)" -ForegroundColor Red;
            return;
        }
        $rateLimitRemainingTime = $null;
        if (!$response.Headers.TryGetValues("RateLimit-Remaining", [ref]$rateLimitRemainingTime)) {
            return;
        }
        $rateLimitRemainingTime = [Int32]::Parse($rateLimitRemainingTime) * 2;
        Write-Host "⚠️ [RateLimit] remaining time $rateLimitRemainingTime MS ⚠️" -ForegroundColor Black -BackgroundColor Red;
        Start-Sleep -Milliseconds $rateLimitRemainingTime;
        return Invoke-Request `
            -path $path `
            -body $body `
            -property $property;
    }
}

function GetSubtitles {
    function GetByTitle {
        $queryBody = @{
            query = $Title
        };

        $Result = Invoke-Request -path "movie/search" -body $queryBody -property "results";
        if ($Result.Length -gt 1) {
            $Selected = Single-Options-Selector.ps1 -Options (
                $Result | ForEach-Object {
                    return @{
                        Key   = "$($_.title)-$($_.releaseYear)-$($_.type)";
                        Value = $_
                    }
                } 
            ) -Title "Found Multiple Results For $Title, Please Select The Correct One.";
            return @($Selected);
        }

        return $Result;
    }

    function GetByImdbId {
        if (!$ShowImdbId) {
            $show = & Imdb-GetShow.ps1 -Name $title -Type $type -Year $Year;
            $ShowImdbId = ($show)?.id;
        }

        if (!$ShowImdbId) {
            return $null;
        }

        $queryBody = @{
            query = $ShowImdbId
        };

        return Invoke-Request -path "movie/search" -body $queryBody -property "results"
    }

    $searchResult = GetByImdbId
    $searchResult ??= GetByTitle
    if ($searchResult.Length -eq 0) {
        Write-Host "No Results Found For $title Or $ShowImdbId" -ForegroundColor Red;
        $queryParams = @("auto_download=true");
        $Season ? ($queryParams += "auto_season=$season") : "";
        $SavePath ? ($queryParams += "auto_save_path=$SavePath") : "";
        $renameTo ? ($queryParams += "auto_rename_to=$renameTo") : "";
        $Episodes ? ($queryParams += "auto_episodes=$(@($Episodes) | ConvertTo-Json -Depth 100 -Compress)") : "";
        Start-Process "$subsourceSiteDomain/search?q=$title&$($queryParams -join "&")" -Wait;
        EXIT;
    }

    $movieInfo = $searchResult[0];
    $name = ($movieInfo.link -split "/")[-1]
    $path = "subtitles/$name";
    if ($season -and $type -eq "Series") {
        $global:subtitlePageLink += "/season-$season"
        $path += "/season-$season";
    }
    $path += "?language=arabic&sort_by_date=false"
    Write-Host "Subtitle Page $global:subtitlePageLink" -ForegroundColor Green;
    return Invoke-Request -path $path -property "subtitles";
}

$downloadSubtitleCache = @{};
function DownloadSubtitle {
    param (
        $sub
    )
    Write-Host "Downloading Subtitle From => "  -NoNewLine;
    Write-Host "$subsourceSiteDomain$($sub.link)" -ForegroundColor Blue;
    Write-Host "Release Name " -NoNewLine;
    Write-Host "$($sub.release_info)" -ForegroundColor Blue;
    if ($downloadSubtitleCache[$sub.id]) {
        return $downloadSubtitleCache[$sub.id];
    }
    $downloadSubDetails = Invoke-Request -path "subtitle/$($sub.link)" -property "subtitle";
    $downloadToken = $downloadSubDetails.download_token;
    $downloadLink = "$baseUrl/subtitle/download/$downloadToken";
    $fileName = $sub.release_info -replace '[<>:"/\\|?*]', ' ' -replace '  *', ' ';
    $tempPath = "$downloadPath/$fileName";
    Invoke-WebRequest -Uri $downloadLink -OutFile $tempPath;
    $extractLocation = "$downloadPath\$( Get-Date -Format 'yyyy-MM-dd-HH-mm-ss' )"
    & 7z  x $tempPath -aoa -bb0 -o"$extractLocation" | Out-Null;
    $downloadSubtitleCache[$sub.id] = $extractLocation;
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
        [string]$release_info,
        [string]$qualityRegex,
        [string[]]$ignoredVersions,
        [string[]]$keywords
    )

    # Check if release matches quality regex
    if ($release_info -notmatch $qualityRegex) {
        return $false
    }

    # Check if any keyword matches
    if ($keywords.Length -gt 0) {

        $keywordMatched = $keywords | Where-Object { $release_info -match $_ }
        if ($keywordMatched) {
            return $true
        }
    }

    # Check if version is ignored
    $isIgnoredVersion = $ignoredVersions | Where-Object { $release_info -match $_ }
    return -not $isIgnoredVersion
}

$arabicSubs = GetSubtitles;
if ($type -eq "Movie") {
    $matchedSubtitle = $arabicSubs | Where-Object { 
        MatchRelease -release_info $_.release_info `
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
        return $_.release_info -replace "\.| ", "" -match $wholeSeasonRegex `
            -or $_.commentary -contains "الموسم كامل" `
            -or $_release_info -match "Complete(\.| )?Season"
    }
);

$arabicSubs = $arabicSubs | Where-Object { $_ -notin $wholeSeasonSubtitles };

$Episodes | ForEach-Object {
    $episode = $_;
    Write-Host "-----" -ForegroundColor Yellow;
    Write-Host "Episode $($episode.Episode)" -ForegroundColor Yellow;
    $episodeNumber = $episode.Episode;
    $qualityRegex = $episode.Quality
    $episodeRegex = $null;
    if ($Title -contains $episodeNumber) {
        $episodeRegex = "(S?0*$season)?(\.| )*(E|\d+X|Episode|EP)0*$episodeNumber(\D+|$)"
    }
    else {
        $episodeNumberGtNine = $episodeNumber -gt 9;
        $episodeRegex = "(\.|\|| |-|E)$($episodeNumberGtNine ? $episodeNumber : "0*$episodeNumber")(\.| |-|\|)"
    }
    $episodeSubtitles = @($arabicSubs | Where-Object { $_.release_info -match $episodeRegex });
    $matchedSubtitle = $episodeSubtitles | Where-Object { 
        MatchRelease -release_info $_.release_info`
            -qualityRegex $qualityRegex `
            -ignoredVersions $episode.IgnoredVersions `
            -keywords $episode.Keywords; 
    } | Select-Object -First 1;

    if (!$matchedSubtitle) {
        Write-Host "Trying complete season subtitle" -ForegroundColor Green;
        $matchedSubtitle = $wholeSeasonSubtitles | Where-Object { 
            MatchRelease -release_info $_.release_info`
                -qualityRegex $qualityRegex `
                -ignoredVersions $episode.IgnoredVersions `
                -keywords $episode.Keywords; 
        } | Select-Object -First 1;
    }

    $matchedSubtitle ??= $episodeSubtitles[0] ?? $wholeSeasonSubtitles[0];
    if (!$matchedSubtitle) {
        Write-Host "CAN'T FIND Subtitle FOR $title => EPISODE $episodeNumber " -ForegroundColor Red -NoNewLine;
        Write-Host "$global:subtitlePageLink" -ForegroundColor Blue;
        
        [Console]::Beep(1000, 500);
        return;
    }

    # . $downloaderScriptPath -DownloadPath $DownloadPath `
    #     -Type "Series" `
    #     -Title $Title `
    #     -Quality $episode.Quality `
    #     -SavePath $episode.SavePath `
    #     -RenameTo $episode.RenameTo `
    #     -Year $episode.Year `
    #     -IgnoredVersions $episode.IgnoredVersions `
    #     -Keywords $episode.Keywords `
    #     -Season $season `
    #     -ShowImdbId $ShowImdbId `
    #     -Episodes @($matchedSubtitle);
        
    $subtitlePath = DownloadSubtitle -sub $matchedSubtitle;
    CopySubtitle -subtitlePath  $subtitlePath `
        -savePath $episode.SavePath `
        -renameTO $episode.RenameTo `
        -episodeRegex $episodeRegex `
        -qualityRegex $qualityRegex;
}

Write-Host "==============================" -ForegroundColor Red;