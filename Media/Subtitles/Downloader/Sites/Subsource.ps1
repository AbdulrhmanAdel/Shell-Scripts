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

    $url = "$baseUrl/$path";
    $result = Invoke-WebRequest -Uri $url -Body $body -Method Post;
    $content = $result.Content | ConvertFrom-Json;

    if ($property) {
        return $content.$property;
    }

    return $content;
}

function GetSubtitles {
    $searchResult = Invoke-Request -path "searchMovie" -body @{
        query = $name
    } -property "found";
    
    if ($searchResult.Length -eq 0) {
        Start-Process "https://subsource.net/search/$name"
        EXIT;
    }

    $subsourceType = $type -eq "S" ? "TVSeries": "Movie";
    $movieInfo = $searchResult | Where-Object {
        $_.type -eq $subsourceType
    } | Select-Object -First 1;
    $movieInfo ??= $searchResult[0];
    
    $global:subtitlePageLink = "https://subsource.net/subtitles/$($movieInfo.linkName)"

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

function DownloadSubtitle {
    param (
        $sub
    )

    Write-Host "Downloading Subtitle: $($sub.releaseName)" -ForegroundColor Yellow;
    $downloadSubDetails = Invoke-Request -path "getSub" -Body @{
        movie = $sub.linkName
        lang  = $sub.lang
        id    = $sub.subId
    } -property "sub";
    
    $downloadToken = $downloadSubDetails.downloadToken;
    $downloadLink = "$baseUrl/downloadSub/$downloadToken";
    $tempPath = "$($env:TEMP)/$($downloadSubDetails.fileName)";
    Invoke-WebRequest -Uri $downloadLink -OutFile $tempPath;
    $savePath ??= "D:/";
    $extractLocation = "$($env:TEMP)\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
    Expand-Archive `
        -Path $tempPath `
        -DestinationPath $extractLocation `
        -Force;

    Remove-Item -LiteralPath $tempPath -Recurse -Force;
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

    if ($episodeRegex) {
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

    Remove-Item -LiteralPath $subtitlePath -Recurse -Force;
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

$Episodes | ForEach-Object {
    $episode = $_;
    $episodeNumber = $episode.Episode;
    $episodeRegex = "(S?0?$season)(E|X)0?$($episodeNumber)";
    $qualityRegex = "$($episode.Quality)"
    Write-Host "Episode $($episodeNumber) => Quality $qualityRegex" -ForegroundColor Red;
    $matchedSubtitle = $null;
    foreach ($arabicSub in $arabicSubs) {
        if ($arabicSub.releaseName -match $episodeRegex) {
            if (! $matchedSubtitle) {
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
        Write-Host "CAN'T FIND Subtitle FOR $name => EPISODE $episodeNumber " -ForegroundColor Red -NoNewLine;
        Write-Host "$global:subtitlePageLink" -ForegroundColor Blue;
        return;
    }

    
    $subtitlePath = DownloadSubtitle -sub  $matchedSubtitle;
    CopySubtitle -subtitlePath  $subtitlePath `
        -savePath $episode.SavePath `
        -renameTO $episode.RenameTo `
        -episodeRegex $episodeRegex `
        -qualityRegex "$qualityRegex";
}

Write-Host "==============================" -ForegroundColor Red;