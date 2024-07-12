$replaceRegex = "\.|-|_|\(|\)";
function RemoveSigns {
    param (
        $text
    )

    return $text -replace $replaceRegex, " " -replace "  +", " "
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
    $moviesName = GetMovieName -fileName $info.Name;
    Start-Process "https://subsource.net/search/$moviesName"
}

