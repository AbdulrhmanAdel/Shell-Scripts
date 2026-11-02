[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Path,
    [Parameter(Mandatory)]
    [string]$Destination,
    # The name to save it as, for downloads with the version in their name (e.g. an AppImage)
    [string]$FileName
)

$result = & "$PSScriptRoot/_Copy.ps1" -Source $Path -Destination $Destination;
$installed = Join-Path $Destination (Split-Path $Path -Leaf);
if ($result.Success -and $FileName) {
    Move-Item -LiteralPath $installed -Destination (Join-Path $Destination $FileName) -Force;
    $installed = Join-Path $Destination $FileName;
}

# Downloads are not executable on Linux, and this installer is for programs (an AppImage, a single binary)
if ($IsLinux -and $result.Success) {
    & chmod +x -- $installed;
}
return $result;