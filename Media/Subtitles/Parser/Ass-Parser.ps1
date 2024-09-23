. Parse-Args.ps1 $args;
$file ??= $args[0];
$encoding ??= & Get-File-Encoding.ps1 $file;
$withStyles ??= $false;
function ParseTimeSpan {
    param (
        $time
    )
    
    return [timespan]::ParseExact($time, "h\:mm\:ss\.ff", $null)
}

function ParseDialogue {
    param ($line)
    return @{
        StartTime = ParseTimeSpan -time $Matches["StartTime"]
        EndTime   = ParseTimeSpan -time $Matches["EndTime"]
        Content   = $Matches["Text"]
        Layer     = $Matches["Layer"]
        Style     = $Matches["Style"]
        Name      = $Matches["Name"]
        MarginL   = $Matches["MarginL"]
        MarginR   = $Matches["MarginR"]
        MarginV   = $Matches["MarginV"]
        Effect    = $Matches["Effect"]
        Line      = $line
    }
}

function ParseStyle {
    param ($line)
    return @{
        Name            = $Matches["Name"]
        Fontname        = $Matches["Fontname"]
        Fontsize        = $Matches["Fontsize"]
        PrimaryColour   = $Matches["PrimaryColour"]
        SecondaryColour = $Matches["SecondaryColour"]
        OutlineColour   = $Matches["OutlineColour"]
        BackColour      = $Matches["BackColour"]
        Bold            = $Matches["Bold"]
        Italic          = $Matches["Italic"]
        Underline       = $Matches["Underline"]
        StrikeOut       = $Matches["StrikeOut"]
        ScaleX          = $Matches["ScaleX"]
        ScaleY          = $Matches["ScaleY"]
        Spacing         = $Matches["Spacing"]
        Angle           = $Matches["Angle"]
        BorderStyle     = $Matches["BorderStyle"]
        Outline         = $Matches["Outline"]
        Shadow          = $Matches["Shadow"]
        Alignment       = $Matches["Alignment"]
        MarginL         = $Matches["MarginL"]
        MarginR         = $Matches["MarginR"]
        MarginV         = $Matches["MarginV"]
        Encoding        = $Matches["Encoding"]
    }
}

$styles = @();
$styleRegex = "^Style: (?<Name>[^,]+),\s*(?<Fontname>[^,]+),\s*(?<Fontsize>[^,]+),\s*(?<PrimaryColour>[^,]+),\s*(?<SecondaryColour>[^,]+),\s*(?<OutlineColour>[^,]+),\s*(?<BackColour>[^,]+),\s*(?<Bold>[^,]+),\s*(?<Italic>[^,]+),\s*(?<Underline>[^,]+),\s*(?<StrikeOut>[^,]+),\s*(?<ScaleX>[^,]+),\s*(?<ScaleY>[^,]+),\s*(?<Spacing>[^,]+),\s*(?<Angle>[^,]+),\s*(?<BorderStyle>[^,]+),\s*(?<Outline>[^,]+),\s*(?<Shadow>[^,]+),\s*(?<Alignment>[^,]+),\s*(?<MarginL>[^,]+),\s*(?<MarginR>[^,]+),\s*(?<MarginV>[^,]+),\s*(?<Encoding>[^,]+)$"
#endregion

$content = Get-Content -LiteralPath $file -Encoding $encoding | ForEach-Object {
    if ($_ -match "Dialogue: (?<Layer>\d+),(?<StartTime>\d{1,2}:\d{2}:\d{2}\.\d{2}),(?<EndTime>\d{1,2}:\d{2}:\d{2}\.\d{2}),(?<Style>[^,]*),(?<Name>[^,]*),(?<MarginL>\d+),(?<MarginR>\d+),(?<MarginV>\d+),(?<Effect>[^,]*),(?<Text>.+)") {
        return ParseDialogue -line $_;
    }

    if ($withStyles) {
        if ($_ -match $styleRegex) {
            $styles += ParseStyle -line $_;
        }
    }
}

return @{
    Content = $content
    Styles  = $styles
};