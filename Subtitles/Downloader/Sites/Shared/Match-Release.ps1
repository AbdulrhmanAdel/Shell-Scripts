param (
    [PsObject[]]$Subtitles = @(),
    [string[]]$SearchKeywords = @(),
    [string[]]$IgnoredVersions = @()
)

$matched = @($Subtitles | Where-Object {
    $sub = $_;
    $hasMatch = $sub.KeyWords | Where-Object {
        $releaseToken = $_;
        if (-not $releaseToken) {
            return $false
        }

        foreach ($ignored in $IgnoredVersions) {
            if ($ignored -and $releaseToken -match $ignored) {
                return $false
            }
        }

        foreach ($searchKeyword in $SearchKeywords) {
            if ($searchKeyword -and $releaseToken -match $searchKeyword) {
                return $true
            }
        }

        return $false
    }

    return $null -ne $hasMatch
})

if ($matched.Count -gt 0) {
    return @{
        HasMatch   = $true;
        FirstMatch = $matched[0];
        Others     = @($matched | Select-Object -Skip 1)
    }
}

return @{
    HasMatch   = $false;
    FirstMatch = $null;
    Others     = @()
}
