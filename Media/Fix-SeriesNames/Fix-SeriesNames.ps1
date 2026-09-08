[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$seriesName = $null;
$season = Input.ps1 -Type Number -Message "Enter Season Number" -DefaultValue 1;
$seasonPrefix = $season -lt 10 ? "S0" : "S";
$Files | ForEach-Object {
    $name = Split-Path -Leaf -Path $_;
    $name = Remove-UnwantedText.ps1 -Text $name;
    $firstDigitIndex = $name.IndexOfAny("0123456789".ToCharArray());
    $nameWithoutDigits = $name.Substring(0, $firstDigitIndex);
    if (! $seriesName) {
        $seriesName = $nameWithoutDigits -replace '-|_', ' ' -replace ' +', ' ';
        $seriesName = $seriesName.Trim()
    }

    $newName = $name -replace $nameWithoutDigits, "$seriesName $($seasonPrefix)$($season)E";
    Rename-Item -Path $_ -NewName $newName;
}

timeout.exe 15;