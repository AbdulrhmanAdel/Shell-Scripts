[CmdletBinding()]
param (
    $CurrentVersion,
    $NewVersion
)

# Pulls "1.2.3" out of things like "v1.2.3", "2.5.2 (472f8fbc8)" or "8.50-6020"
function ConvertTo-CleanVersion {
    param ($Value)

    if ("$Value" -match '\d+(\.\d+){0,3}') {
        $clean = $Matches[0];
        # [version] needs at least major.minor
        return [version]($clean -match '\.' ? $clean : "$clean.0");
    }
    return $null;
}

if (!$CurrentVersion -or !$NewVersion) {
    return $true;
}

$oldVersion = ConvertTo-CleanVersion $CurrentVersion
$newVersion = ConvertTo-CleanVersion $NewVersion
if (!$oldVersion -or !$newVersion) {
    # Not numeric at all, so the best we can say is whether it changed
    return "$CurrentVersion".Trim() -ne "$NewVersion".Trim();
}

return $newVersion -gt $oldVersion;
