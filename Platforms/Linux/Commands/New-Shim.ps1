[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Name,
    [string] $Target,
    [string] $Icon
)

if (!$Target) {
    $Target = File-Picker.ps1 -Title "Select target for shim '$Name'" -Required;
}
$Target = (Resolve-Path -LiteralPath $Target).Path;

if ($Target -notmatch '^(.*?/Programming/Programs|.*?/Programs)/') {
    throw "'$Target' is not inside a Programs folder.";
}

$shims = "$($Matches[1])/00-Maintenance/Shims";
New-Item -ItemType Directory -Force $shims | Out-Null;
New-Item -ItemType SymbolicLink -Path "$shims/$Name" -Target $Target -Force | Out-Null;
Write-Host "$Name -> $Target" -ForegroundColor Green;
