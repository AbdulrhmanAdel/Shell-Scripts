param (
    [PsObject[]]$Subtitles = @(),
    [string[]]$SearchKeywords = @(),
    [string[]]$IgnoredVersions = @(),
    [string]$FileName
)

function Get-ReleaseInfo {
    param (
        [string]$Name
    )

    $normalized = " $($Name.ToLower()) " `
        -replace 'blu[\s._-]?ray|bdrip|brrip|bdremux|[^a-z]bd[^a-z]', ' bluray ' `
        -replace 'web[\s._-]?(dl|rip|hd)?', ' web ' `
        -replace 'dvd[\s._-]?rip', ' dvd ' `
        -replace 'h[\s._]?26([45])', ' x26$1 ' `
        -replace 'hevc', ' x265 ';
    $tokens = @($normalized -split '[^a-z0-9]+' | Where-Object { $_ } | Select-Object -Unique);

    return @{
        Tokens     = $tokens
        Source     = $tokens | Where-Object { $_ -in @('bluray', 'web', 'hdtv', 'dvd', 'hdrip') } | Select-Object -First 1
        Resolution = $tokens | Where-Object { $_ -match '^\d{3,4}p$' } | Select-Object -First 1
        Group      = $Name -match '-(?<Group>[a-z0-9]+)(\.[a-z]{2,3})?[\])]?$' ? $Matches['Group'].ToLower() : $null
    }
}

function Get-ReleaseScore {
    param (
        $File,
        [string]$Release
    )

    $info = Get-ReleaseInfo -Name $Release;
    $score = 0;
    if ($File.Source -and $File.Source -eq $info.Source) { $score += 10 }
    if ($File.Group -and $File.Group -eq $info.Group) { $score += 5 }
    if ($File.Resolution -and $File.Resolution -eq $info.Resolution) { $score += 3 }
    $score += @($info.Tokens | Where-Object { $_ -in $File.Tokens }).Count;
    foreach ($ignored in $IgnoredVersions) {
        if ($ignored -and $Release -match $ignored) { $score -= 15 }
    }

    return $score
}

$filtered = @($Subtitles | Where-Object {
        if ($SearchKeywords.Count -eq 0) {
            return $true
        }

        return $null -ne ($_.KeyWords | Where-Object {
                $releaseToken = $_;
                $SearchKeywords | Where-Object { $_ -and $releaseToken -match $_ }
            } | Select-Object -First 1)
    })

$file = Get-ReleaseInfo -Name ($FileName ?? "");
$index = 0;
$ranked = @($filtered | ForEach-Object {
        $sub = $_;
        $scores = @($sub.KeyWords | Where-Object { $_ } | ForEach-Object { Get-ReleaseScore -File $file -Release $_ });
        [PSCustomObject]@{
            Sub   = $sub
            Score = $scores.Count -gt 0 ? ($scores | Measure-Object -Maximum).Maximum : 0
            Index = $index++
        }
    } | Sort-Object -Property @{ Expression = 'Score'; Descending = $true }, @{ Expression = 'Index' } | ForEach-Object { $_.Sub })

if ($ranked.Count -gt 0) {
    return @{
        HasMatch   = $true;
        FirstMatch = $ranked[0];
        Others     = @($ranked | Select-Object -Skip 1)
    }
}

return @{
    HasMatch   = $false;
    FirstMatch = $null;
    Others     = @()
}
