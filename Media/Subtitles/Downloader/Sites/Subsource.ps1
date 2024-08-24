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

function DownloadSubtitle {
    param (
        $sub,
        $savePath,
        $renameTo
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

    $files = @(Get-ChildItem -LiteralPath $extractLocation -Include *.ass, *.srt);
    

    $fileIndex = 0;
    $files | ForEach-Object {
        $file = $files[$fileIndex];
        $finalName = $file.Name -replace $file.Extension, "";
        if ($renameTo) {
            $finalName = $renameTo;
        }

        if ($fileIndex -gt 0) {
            $finalName += "($fileIndex)"
        }

        Copy-Item -LiteralPath $file.FullName `
            -Destination "$savePath/$($finalName)$($file.Extension)";

        $fileIndex++;
    }

    Remove-Item -LiteralPath $extractLocation -Recurse -Force;
    Remove-Item -LiteralPath $tempPath -Recurse -Force;
}

$searchResult = Invoke-Request -path "searchMovie" -body @{
    query = $name
} -property "found";

if ($searchResult.Length -eq 0) {
    Start-Process "https://subsource.net/search/$name"
    EXIT;
}

$movieInfo = $searchResult[0];
 
$body = @{
    langs     = @("Arabic")
    movieName = $movieInfo.linkName
};

if ($season) {
    $body["season"] = "season-$season";
}

$subtitles = Invoke-Request -path "getMovie" -Body $body -property "subs";
$arabicSubs = $subtitles | Where-Object {
    return $_.lang -eq "Arabic" 
}

if ($type -eq "M") {
    $sub = $arabicSubs | Where-Object {
        $_.releaseName -match $Quality
    };
    DownloadSubtitle -sub $sub[0] `
        -savePath $savePath `
        -renameTO $renameTo;
    Exit;
}

# $subs = $arabicSubs | Group-Object -Property subId | Foreach-Object {
#     $subs = $_. Group;

#     return @{
#         SubId    = $_.Name
#         LinkName = $subs[0].linkName
#         Subs     = $subs
#     }
# } | ForEach-Object {
#     $episodeRegex = "(S?0?$season)(E|X)0?$($_.Episode)";
#     $sub = $_.Subs[0];
#     $sub.releaseName -match $episodeRegex;
#     return @{
#         SubId    = $_.SubId
#         LinkName = $_.LinkName
#         Releases = $_.Releases
#         Episode  = $_.Episode
#     }
# }

$Episodes | ForEach-Object {
    $episode = $_;
    $episodeRegex = "(S?0?$season)(E|X)0?$($_.Episode)";
    $qualityRegex = "$($_.Quality)"
    Write-Host "Episode $($_.Episode)" -ForegroundColor Red;
    $sub = $null;
    foreach ($arabicSub in $arabicSubs) {
        if ($arabicSub.releaseName -match $episodeRegex) {
            if (!$sub) {
                $sub = $arabicSub;
            }

            if ($arabicSub.releaseName -match $qualityRegex) {
                $sub = $arabicSub;
                break;
            }
        }
    }

    DownloadSubtitle -sub $sub `
        -savePath $episode.SavePath `
        -renameTO $episode.RenameTo;
}

Write-Host "==============================" -ForegroundColor Red;