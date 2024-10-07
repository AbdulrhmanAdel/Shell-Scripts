$parentDirectory = "$PSScriptRoot\Shared"
# Retrieve all directory paths
$directories = Get-ChildItem -Path $parentDirectory -Directory -Recurse | Where-Object {
    return $_.FullName -notmatch "Ignore|Modules"
} | Select-Object -ExpandProperty FullName

# Current system path
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User");
$pathes = $currentPath -split ";" | Where-Object {
    return !$_.StartsWith($parentDirectory)
};

$pathes += $directories + $parentDirectory;
# Set the new path
[System.Environment]::SetEnvironmentVariable("Path", $pathes -join ";", "User");

timeout 15;
