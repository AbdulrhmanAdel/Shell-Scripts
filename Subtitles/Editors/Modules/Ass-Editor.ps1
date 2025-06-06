[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

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


$supportedEdits = @(
    @{
        Type         = "Number"
        $Value       = $null
        Name         = $MarginVKey 
        DefaultValue = 22
    },
    @{
        Type         = "Number"
        $Value       = $null
        Name         = $FontSizeKey
        DefaultValue = 22
    },
    @{
        Type         = "Text"
        $Value       = $null
        Name         = $PrimaryColourKey
        DefaultValue = "FFFFFF"
    }
);

$Edits = $supportedEdits | ForEach-Object {
    $value = Input.ps1 -Type $_.Type -DefaultValue $_.DefaultValue -Message "$($_.Name) - Default is $($_.DefaultValue)?";
    $_.Value = $value ?? $_.DefaultValue;
} | Where-Object { !!$_.Value };


#endRegion

$styleRegex = "^Style: (?<$NameKey>[^,]+),\s*(?<$FontnameKey>[^,]+),\s*(?<$FontsizeKey>[^,]+),\s*(?<$PrimaryColourKey>[^,]+),\s*(?<$SecondaryColourKey>[^,]+),\s*(?<$OutlineColourKey>[^,]+),\s*(?<$BackColourKey>[^,]+),\s*(?<$BoldKey>[^,]+),\s*(?<$ItalicKey>[^,]+),\s*(?<$UnderlineKey>[^,]+),\s*(?<$StrikeOutKey>[^,]+),\s*(?<$ScaleXKey>[^,]+),\s*(?<$ScaleYKey>[^,]+),\s*(?<$SpacingKey>[^,]+),\s*(?<$AngleKey>[^,]+),\s*(?<$BorderStyleKey>[^,]+),\s*(?<$OutlineKey>[^,]+),\s*(?<$ShadowKey>[^,]+),\s*(?<$AlignmentKey>[^,]+),\s*(?<$MarginLKey>[^,]+),\s*(?<$MarginRKey>[^,]+),\s*(?<$MarginVKey>[^,]+),\s*(?<$EncodingKey>[^,]+)$"
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

    $encoding = & Get-FileEncoding.ps1 $path;
    Write-Host "USED ENCODING $encoding" -ForegroundColor Green;
    Write-Host "Editing $($path)" -ForegroundColor Green;
    $content = Get-Content -LiteralPath $path -Encoding $encoding;
    $content = $content | ForEach-Object {
        if ($_ -match $styleRegex) {
            # if (!($Matches["Name"].Contains("Default"))) { 
            #     return $_;
            # }
            $Edits | ForEach-Object {
                Update -variableName $_;
            }
            return GroupLine;
        }

        return $_;
    }

    $content | Set-Content -LiteralPath $path  -Encoding $encoding;
    Write-Host "Ended $($path)" -ForegroundColor Blue;
    Write-Host "=========================" -ForegroundColor Yellow;
}
#endregion


@($Files) | ForEach-Object { Edit -path $_ };

timeout 15;