$Path = [System.Environment]::GetEnvironmentVariable("Path", "User");

$Special = "[<VerySpecialCharacter>]";
$set = @{};
$Path -split ";" | ForEach-Object {
    $set[$_ -replace "\/", $Special -replace "\\", $Special] = $true;
};

$finalPath = $set.Keys | ForEach-Object {
    return $_.Replace($Special, "\");
} | Where-Object {$_ -ne ""}

$newPath = $finalPath -join ";";
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "User");