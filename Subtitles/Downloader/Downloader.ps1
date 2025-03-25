[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths
)


function HandleMovies {
    param($subs)
    $movies = $subs | Where-Object { $_.Details.Type -eq "Movie" };
    $movies | Where-Object {
        $info = $_.Info;
        $details = $_.Details;
        Write-Host $details;    
        & "$($PSScriptRoot)/Sites/Subsource.ps1" `
            -DownloadPath $downloadPath `
            -Type $details.Type `
            -Title $details.Title `
            -Quality $details.Quality `
            -SavePath $info.Directory.FullName `
            -RenameTo $_.Name `
            -Year $details.Year `
            -IgnoredVersions $details.IgnoredVersions `
            -Keywords $details.Keywords;
    }
}

function HandleSeries {
    param (
        $subs
    )
    $series = $subs | Where-Object { $_.Details.Type -eq "Series" };
    if ($series.Length -eq 0) {
        return;
    }
    $final = @{};
    function GroupSeries {
        param (
            $episode
        )
        $details = $episode.Details;
        $episodeInfo = [PSCustomObject]@{
            Episode         = $details.Episode
            Quality         = $details.Quality
            SavePath        = $episode.Info.Directory.FullName;
            RenameTo        = $episode.Name;
            Year            = $details.Year
            IgnoredVersions = $details.IgnoredVersions
            Keywords        = $details.Keywords
        };

        $serie = $final[$details.Title];
        if ($serie) {
            $season = $serie[$details.Season] ?? @();
            $serie[$details.Season] = $season + $episodeInfo ;
            return;
        }

        $final[$details.Title] = @{
            $details.Season = @($episodeInfo)
        }
    }

    $series | ForEach-Object { GroupSeries -episode $_ };
    $final.Keys | ForEach-Object {
        $serieName = $_;
        $serie = $final[$_];
        $serie.Keys | ForEach-Object {
            $seasonEpisodes = $serie[$_] | Sort-Object -Property Episode;
            $episodeWithYear = $seasonEpisodes | Where-Object { !!$_.Year } | Select-Object -First  1;
            & "$($PSScriptRoot)/Sites/Subsource.ps1" `
                -DownloadPath $downloadPath `
                -Type "Series" `
                -Title $serieName `
                -Season $_ `
                -Year $episodeWithYear.Year `
                -Episodes $seasonEpisodes; 
        }
    }
}

$files = @();
$Paths | Where-Object {
    # $extension = [System.IO.Path]::GetExtension($_);
    # $fileName = Split-Path -Leaf -Path $_;
    # if (
    #     (
    #         Test-Path -LiteralPath ($_ -replace $extension, '.srt') -or `
    #             Test-Path -LiteralPath ($_ -replace $extension, '.ass')
    #     ) -and `
    #       !(Prompt.ps1 -Message "$fileName Already has Subtitle Do you want to override")) {
    #     return $false;
    # }

    return $true;
} | ForEach-Object {
    $info = Get-Item -LiteralPath $_ -ErrorAction Ignore;
    if (!$info) {
        return;
    }

    if ($info -is [System.IO.FileInfo]) {
        if ($info.Extension -in @(".mkv", ".mp4") -and !(Has-SoftSubbedArabic.ps1 -Path $_)) {
            $files += $info;
        }
        return;
    }


    $childern = Get-ChildItem -LiteralPath $info.FullName -Recurse -Include *.mkv, *.mp4;
    $files += $childern;
}

$subs = $files | ForEach-Object {
    $details = & Get-ShowDetails.ps1 -Path $_.FullName;
    if (!$details) { return $null; }
    $info = $details.Info;
    $name = $info.Name -replace $info.Extension, "";
    return @{
        Name    = $name
        Info    = $info
        Details = $details
    }
} | Where-Object {
    return $null -ne $_;
};


$downloadPath = "$($env:TEMP)/MyScripts/Subtitle-Downloader";
if (!(Test-Path -LiteralPath $downloadPath)) {
    New-Item -Path $downloadPath -ItemType Directory -Force;
}
HandleMovies -subs $subs;
HandleSeries -subs $subs;
Remove-Item  -LiteralPath $downloadPath -Force -Recurse;
timeout.exe 30;