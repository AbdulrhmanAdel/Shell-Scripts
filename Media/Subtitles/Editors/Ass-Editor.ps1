$files = @($args | Where-Object { $_.ToString().EndsWith(".ass") });

#region Keys
$NameKey = "Name";
$FontnameKey = "Fontname";
$FontsizeKey = "Fontsize";
$PrimaryColourKey = "PrimaryColour";
$SecondaryColourKey = "SecondaryColour";
$OutlineColourKey = "OutlineColour";
$BackColourKey = "BackColour";
$BoldKey = "Bold";
$ItalicKey = "Italic";
$UnderlineKey = "Underline";
$StrikeOutKey = "StrikeOut";
$ScaleXKey = "ScaleX";
$ScaleYKey = "ScaleY";
$SpacingKey = "Spacing";
$AngleKey = "Angle";
$BorderStyleKey = "BorderStyle";
$OutlineKey = "Outline";
$ShadowKey = "Shadow";
$AlignmentKey = "Alignment";
$MarginLKey = "MarginL";
$MarginRKey = "MarginR";
$MarginVKey = "MarginV";
$EncodingKey = "Encoding";

$allEdits = @(
    $FontnameKey,
    $FontsizeKey,
    $PrimaryColourKey,
    $SecondaryColourKey,
    $OutlineColourKey,
    $BackColourKey,
    $BoldKey,
    $ItalicKey,
    $UnderlineKey,
    $StrikeOutKey,
    $ScaleXKey,
    $ScaleYKey,
    $SpacingKey,
    $AngleKey,
    $BorderStyleKey,
    $OutlineKey,
    $ShadowKey,
    $AlignmentKey,
    $MarginLKey,
    $MarginRKey,
    $MarginVKey,
    $EncodingKey
);

$supportedEdits = @(
    $MarginVKey ,
    $FontSizeKey
);

$edits = @{};
#endRegion

$styleRegex = "^Style: (?<$NameKey>[^,]+),\s*(?<$FontnameKey>[^,]+),\s*(?<$FontsizeKey>[^,]+),\s*(?<$PrimaryColourKey>[^,]+),\s*(?<$SecondaryColourKey>[^,]+),\s*(?<$OutlineColourKey>[^,]+),\s*(?<$BackColourKey>[^,]+),\s*(?<$BoldKey>[^,]+),\s*(?<$ItalicKey>[^,]+),\s*(?<$UnderlineKey>[^,]+),\s*(?<$StrikeOutKey>[^,]+),\s*(?<$ScaleXKey>[^,]+),\s*(?<$ScaleYKey>[^,]+),\s*(?<$SpacingKey>[^,]+),\s*(?<$AngleKey>[^,]+),\s*(?<$BorderStyleKey>[^,]+),\s*(?<$OutlineKey>[^,]+),\s*(?<$ShadowKey>[^,]+),\s*(?<$AlignmentKey>[^,]+),\s*(?<$MarginLKey>[^,]+),\s*(?<$MarginRKey>[^,]+),\s*(?<$MarginVKey>[^,]+),\s*(?<$EncodingKey>[^,]+)$"
$startFrom = Read-Host "StartFrom?";
if ($startFrom) {
    if ($startFrom -match $styleRegex) {
        $allEdits | ForEach-Object {
            $edits[$_] = $Matches[$_];
        }
    }
}

$supportedEdits | ForEach-Object {
    $value = Read-Host "$($_)?";
    if ($value) {
        $edits[$_] = $value;
    }
}

#region Functions
function GroupLine {
    return "Style: $($Matches['Name']),$($Matches['Fontname']),$($Matches['Fontsize']),$($Matches['PrimaryColour']),$($Matches['SecondaryColour']),$($Matches['OutlineColour']),$($Matches['BackColour']),$($Matches['Bold']),$($Matches['Italic']),$($Matches['Underline']),$($Matches['StrikeOut']),$($Matches['ScaleX']),$($Matches['ScaleY']),$($Matches['Spacing']),$($Matches['Angle']),$($Matches['BorderStyle']),$($Matches['Outline']),$($Matches['Shadow']),$($Matches['Alignment']),$($Matches['MarginL']),$($Matches['MarginR']),$($Matches['MarginV']),$($Matches['Encoding'])";
}

function Update {
    param (
        [string]$variableName
    )

    $value = $edits[$variableName];
    $Matches[$variableName] = $value;
}
function Edit {
    param (
        [string]$path
    )

    Write-Host "Editing $($path)" -ForegroundColor Green;
    $content = Get-Content -LiteralPath $path;
    $content = $content | ForEach-Object {
        if ($_ -match $styleRegex) {
            if (!($Matches["Name"].Contains("Default"))) { 
                return $_;
            }
            $edits.Keys | ForEach-Object {
                Update -variableName $_;
            }
            return GroupLine;
        }

        return $_;
    }

    $content | Set-Content -LiteralPath $path -Encoding utf8;
    Write-Host "Ended $($path)" -ForegroundColor Blue;
    Write-Host "=========================" -ForegroundColor Yellow;
}
#endregion


$files | ForEach-Object { Edit -path $_ };

timeout 15;