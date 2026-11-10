. "$PSScriptRoot\Build-EpisodeMatcher.ps1"

function Invoke-SubtitleProvider {
    param (
        [PsObject]$Show,
        [string]$Quality,
        [string]$SavePath,
        [string]$RenameTo,
        [string[]]$IgnoredVersions,
        [string[]]$Keywords
    )

    $Type = $Show.Type
    $Title = $Show.Title
    $Season = $Show.Season
    $Episodes = $Show.Episodes

    Write-Host "==============================" -ForegroundColor Red;
    Write-Host "Handling: " -ForegroundColor Green -NoNewline;
    Write-Host "$Title " -ForegroundColor DarkBlue -NoNewline;
    Write-Host "Type: $Type " -ForegroundColor Green -NoNewline;
    if ($Type -eq "Series") {
        Write-Host "Season: $Season; " -ForegroundColor Green -NoNewline;
        Write-Host "Episodes: " -ForegroundColor Green -NoNewline;
        Write-Host ($Episodes | ForEach-Object { $_.Episode }) -Separator ", " -ForegroundColor Green -NoNewline;
    }
    Write-Host ""

    $handle = Find-Show -Show $Show
    if ($handle.PageUrl) {
        Write-Host "[INFO]: Link `e]8;;$($handle.PageUrl)`e\$($handle.PageUrl)`e]8;;`e\" -ForegroundColor Cyan;
    }

    $candidates = @(Get-SubtitleCandidates -ShowHandle $handle)
    Write-Host "[INFO]: Candidate subtitles: $($candidates.Count)" -ForegroundColor Cyan;

    if ($Type -eq "Movie") {
        $matchResult = & "$PSScriptRoot\Match-Release.ps1" -Subtitles $candidates `
            -IgnoredVersions $IgnoredVersions `
            -FileName $RenameTo;

        if (-not $matchResult.HasMatch) {
            Write-Host "CAN'T FIND Subtitle FOR $Title" -ForegroundColor Red;
            if ($handle.PageUrl) { Start-Process $handle.PageUrl; }
            [Console]::Beep(1000, 500);
            Write-Host "==============================" -ForegroundColor Red;
            return
        }

        Write-Host "[MATCH]: $($matchResult.Others.Count + 1) candidate(s) matched, using: " -ForegroundColor DarkGray -NoNewline;
        Write-Host ($matchResult.FirstMatch.KeyWords -join " | ") -ForegroundColor DarkYellow;

        $subtitlePath = & "$PSScriptRoot\Download-Subtitle.ps1" `
            -DownloadRequestArgs (Get-SubtitleDownloadArgs -Subtitle $matchResult.FirstMatch.Data);

        $filterFn = {
            param ($Name)
            return $Name -match $Quality
        }
        & "$PSScriptRoot\Copy-Subtitle.ps1" `
            -SubtitlePath $subtitlePath `
            -SavePath $SavePath `
            -RenameTo $RenameTo `
            -Filter $filterFn;

        Write-Host "==============================" -ForegroundColor Red;
        return
    }

    $openedSites = @();
    $Episodes | ForEach-Object {
        $episode = $_;
        Write-Host "-----" -ForegroundColor Yellow;
        Write-Host "Episode $($episode.Episode)" -ForegroundColor Yellow;
        $episodeNumber = $episode.Episode;
        $episodeRegex = Get-EpisodeRegex -Title $Title -Season $Season -EpisodeNumber $episodeNumber;
        Write-Host "[INFO]: Episode Pattern: $episodeRegex" -ForegroundColor DarkGray;

        $episodeMatch = & "$PSScriptRoot\Match-Release.ps1" -Subtitles $candidates `
            -IgnoredVersions $episode.IgnoredVersions `
            -SearchKeywords @($episodeRegex) `
            -FileName $episode.RenameTo;

        if (-not $episodeMatch.HasMatch) {
            Write-Host "CAN'T FIND Subtitle FOR $Title => EPISODE $episodeNumber " -ForegroundColor Red -NoNewLine;
            Write-Host "$($handle.PageUrl)" -ForegroundColor Blue;
            if ($handle.PageUrl -and $openedSites -notcontains $handle.PageUrl) {
                $openedSites += $handle.PageUrl;
                Start-Process $handle.PageUrl;
            }
            [Console]::Beep(1000, 500);
            return
        }

        $chosen = $episodeMatch.FirstMatch;
        Write-Host "[MATCH]: $($episodeMatch.Others.Count + 1) episode candidate(s), using: " -ForegroundColor DarkGray -NoNewline;
        Write-Host ($chosen.KeyWords -join " | ") -ForegroundColor DarkYellow;

        $subtitlePath = & "$PSScriptRoot\Download-Subtitle.ps1" `
            -DownloadRequestArgs (Get-SubtitleDownloadArgs -Subtitle $chosen.Data);

        $filterFn = {
            param ($Name)
            return $Name -match $episodeRegex
        }

        & "$PSScriptRoot\Copy-Subtitle.ps1" `
            -SubtitlePath $subtitlePath `
            -SavePath $episode.SavePath `
            -RenameTo $episode.RenameTo `
            -Filter $filterFn;
    }

    Write-Host "==============================" -ForegroundColor Red;
}
