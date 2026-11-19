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

$oldClean = ConvertTo-CleanVersion $CurrentVersion
$newClean = ConvertTo-CleanVersion $NewVersion
if (!$oldClean -or !$newClean) {
    # Not numeric at all, so the best we can say is whether it changed
    return "$CurrentVersion".Trim() -ne "$NewVersion".Trim();
}

if ($newClean -ne $oldClean) {
    return $newClean -gt $oldClean;
}

# Same number: a pre-release label right after it decides, so "1.0.0-rc.4" -> "1.0.0-rc.5" -> "1.0.0" are each newer.
# Only these labels, so build suffixes like "8.50-6020" or a commit hash keep meaning "the same version".
function Get-PreRelease {
    param ($Value)

    $ranks = @{ alpha = 0; beta = 1; pre = 2; preview = 2; rc = 3 };
    # Right after the first number, the one ConvertTo-CleanVersion compares
    if ("$Value" -match '^\D*\d+(\.\d+){0,3}[-.]?(?<Label>alpha|beta|preview|pre|rc)\.?(?<Number>\d*)(?![a-z])') {
        return [pscustomobject]@{ Rank = $ranks[$Matches.Label.ToLower()]; Number = $Matches.Number ? [int]$Matches.Number : 0 };
    }
    # A release, which comes after all of its pre-releases
    return [pscustomobject]@{ Rank = 99; Number = 0 };
}

$oldPre = Get-PreRelease $CurrentVersion;
$newPre = Get-PreRelease $NewVersion;
if ($newPre.Rank -ne $oldPre.Rank) {
    return $newPre.Rank -gt $oldPre.Rank;
}
return $newPre.Number -gt $oldPre.Number;
