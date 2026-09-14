function Get-EpisodeRegex {
    param (
        [string]$Title,
        $Season,
        $EpisodeNumber
    )

    if ($Title -contains $EpisodeNumber) {
        return "(S?0*$Season)?(\.| )*(E|\d+X|Episode|EP)0*$EpisodeNumber(\D+|$)"
    }

    $episodeNumberGtNine = $EpisodeNumber -gt 9
    return "(\.|\|| |-|E)$($episodeNumberGtNine ? $EpisodeNumber : "0*$EpisodeNumber")(\.| |-|\||$)"
}
