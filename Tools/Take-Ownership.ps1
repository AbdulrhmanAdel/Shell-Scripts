[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

if (!$IsWindows) {
    $owner = "$(id -un):$(id -gn)";
    Write-Host "Taking ownership as ${owner}:";
    $Files | ForEach-Object { Write-Host "  $_"; };
    & sudo chown -R -- $owner @Files;
    Write-Host ($LASTEXITCODE -eq 0 ? "Done." : "Failed.");
    return;
}

& Run-AsAdmin.ps1 -Arguments ($Files | ForEach-Object {return """$_"""});
Write-Host $Files;
$takeOwn = "TakeOwn";
foreach ($file in $Files) {
    $fileInfo = Get-Item -LiteralPath $file;
    if ($fileInfo -is [System.IO.FileInfo]) {
        &$takeOwn /f "$file"
    }
    else {
        $gitPath = "$file\.git";
        if (Test-Path -LiteralPath $gitPath) {
            &$takeOwn /f "$file"
            $file = $gitPath;
        }
        &$takeOwn /f "$file" /r /d y
    }
    Write-Output "TakeDown finished for $file"
}

Timeout.ps1 5;
