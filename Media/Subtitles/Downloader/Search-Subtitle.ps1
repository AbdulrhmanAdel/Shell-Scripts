$replaceRegex = "\.|-|_|\(|\)";
function RemoveSigns {
    param (
        $text
    )

    return ($text -replace $replaceRegex, " " -replace "  +", " ").Trim();
}

function IsSubtitleExists {
    param (
        $info
    )
    
    return !!(@(".ass", ".srt") | Where-Object {
            return Test-Path -LiteralPath ($info.FullName -replace $info.Extension, $_)
        });
}

function GetSerieName() {
    param (
        [string]$fileName
    )

    if ($fileName -match "(?i)(?<Name>.*)((S|Season)\d+)(Episode|Ep|E|[-,|,_,*,#,\.]|\[| |\dx)(?<EpisodeNumber>\d+)([-,|,_,*,#,\.]| |\]|v\d+)") {
        return $Matches["Name"];
    }

    return $null;
}

function GetMovieName {
    param (
        $fileName
    )

    $match = [regex]::Match($fileName, "720|480|1080")
    if ($match.Success) {
        $Index = $Match.Index;
        $name = RemoveSigns -text $fileName.Substring(0, $Index);
        $name = $name.Trim();
        return $name;
    }

    return $fileName;
}

$args | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object {
    $info = Get-Item -LiteralPath $_;
    if (IsSubtitleExists -info $info) {
        return $null;
    }

    $serieName = GetSerieName -fileName $info.Name;
    if ($serieName) {
        return RemoveSigns -text $serieName;
    }

    return GetMovieName -fileName $info.Name;
} | Group-Object { return $_; } | ForEach-Object {
    if (!$_.Name) { return }
    Start-Process "https://subsource.net/search/$($_.Name)"
}

