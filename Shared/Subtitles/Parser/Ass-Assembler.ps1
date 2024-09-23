function SerializeTimeSpan ($timeSpan) {
    return $timeSpan.ToString("hh\:mm\:ss\.ff");
}

function ParseDialogue {
    param (
        $dialogue
    )

    return "Dialogue: $($dialogue.Layer),$(SerializeTimeSpan($dialogue.StartTime)),$(SerializeTimeSpan($dialogue.EndTime)),$($dialogue.Style),$($dialogue.Name),$($dialogue.MarginL),$($dialogue.MarginR),$($dialogue.MarginV),$($dialogue.Effect),$($dialogue.Content -join '')"
}

function ParseStyles {
    param (
        $styles
    )

    if (!$styles -or $styles.Length -eq 0) {
        return "Style: Default,Arial,16,&Hffffff,&Hffffff,&H0,&H0,0,0,0,0,100,100,0,0,1,1,0,2,10,10,10,1"
    }
    
    return $styles | ForEach-Object {
        return "Style: $($_.Name),$($_.Fontname),$($_.Fontsize),$($_.PrimaryColour),$($_.SecondaryColour),$($_.OutlineColour),$($_.BackColour),$($_.Bold),$($_.Italic),$($_.Underline),$($_.StrikeOut),$($_.ScaleX),$($_.ScaleY),$($_.Spacing),$($_.Angle),$($_.BorderStyle),$($_.Outline),$($_.Shadow),$($_.Alignment),$($_.MarginL),$($_.MarginR),$($_.MarginV),$($_.Encoding)"
    }
}

. Parse-Args.ps1 $args;
$dialogs ??= $args[0];
$outputPath ??= $args[1];
$encoding ??= "UTF8"

@(
    "[Script Info]",
    "ScriptType: v4.00+",
    "Collisions: Normal",
    "PlayResX: 384",
    "PlayResY: 288",
    "Timer: 100.0000",
    "",
    "[V4+ Styles]",
    "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding",
    (ParseStyles -styles $dialogs.Styles),
    "",
    "[Events]",
    $dialogs.Content | ForEach-Object {
        $finalContent += ParseDialogue -dialogue $_;
    }
) | Set-Content -LiteralPath $outputPath -Encoding $encoding;