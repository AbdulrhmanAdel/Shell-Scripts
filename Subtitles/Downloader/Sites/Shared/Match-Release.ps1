param (
    [PsObject[]]$Subtitles = @(),
    [string[]]$keywords = @(),
    [string[]]$IgnoredVersions = @()
)

$matched = $Subtitles | Where-Object {
    $sub = $_;
    $hasMatch = $sub.KeyWords | Where-Object {
        $keywords = $_;
        # If no keywords supplied -> match
        if (-not $keywords -or $keywords.Length -eq 0) {
            return $false 
        }

        return $keywords | Where-Object {
            $kw = $_;
            # Ignore if in ignored versions
            if ($IgnoredVersions -and $IgnoredVersions.Length -gt 0) {
                foreach ($ignored in $IgnoredVersions) {
                    if ($kw -match $ignored) {
                        return $false
                    }
                }
            }

            # Check for match
            foreach ($keyword in $keywords) {
                if ($kw -match [regex]::Escape($keyword)) {
                    return $true
                }
            }

            return $false
        }
    }

    return $hasMatch -ne $null
}

if ($matched.Count -gt 0) {
    return @{
        HasMatch   = $true;
        FirstMatch = $matched[0];
        Others     = $matched[1..($matched.Count - 1)]
    }
}

return @{
    HasMatch   = $false;
    FirstMatch = $null;
    Others     = @()
}