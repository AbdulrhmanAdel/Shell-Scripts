[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)
$outputPath = Folder-Picker.ps1 -InitialDirectory $Files[0];
$Files  | ForEach-Object {
    $content = @(
        "@echo off"
        "echo." 
        "`"$_`" %*"
    )

    $FileName = (Split-Path -Path $_ -Leaf) -replace "\..*$", ".bat";
    Set-Content -Path "$outputPath/$FileName" -Value $content -Encoding UTF8 -Force;
}

