[CmdletBinding()]
param (
    $CurrentVersion,
    $NewVersion
)

if (!$CurrentVersion -or !$NewVersion) {
    return $true;
}

$oldVersion = [version]$CurrentVersion
$newVersion = [version]$NewVersion

return $newVersion -gt $oldVersion;