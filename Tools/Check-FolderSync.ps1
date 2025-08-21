[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]
    $Source,
    [Parameter(Mandatory, Position = 1)]
    [string]
    $Target,
    [bool]
    $CheckHashes,
    [bool]
    $ReverseCheck,
    [switch]
    $Timeout
)

$script:hasMismatch = $false;
$script:mismatches = @();
$global:checkedFolder = 0;
$global:checkedFiles = 0;
function GetTargetFromSource {
    param (
        $SourcePath
    )

    return $SourcePath -replace [regex]::Escape($Source), $Target;
}
function CheckFiles {
    param (
        [string]$FolderSource
    )

    $TargetSource = GetTargetFromSource -SourcePath $FolderSource;
    Get-ChildItem -LiteralPath $FolderSource -File | ForEach-Object {
        $global:checkedFiles += 1;
        $filePath = "$TargetSource\$($_.Name)";
        if (-not (Test-Path -LiteralPath $filePath)) {
            Write-Host "File not found: Source: $($_.FullName) => Target: $filePath" -ForegroundColor Green;
            $script:hasMismatch = $true;
            $script:mismatches += @{
                Source = $_.FullName;
                Target = $filePath;
                Reason = "File not found";
            };
        }

        if ($CheckHashes) {
            Write-Host "Checking hash for file: $filePath" -NoNewLine -ForegroundColor Cyan;
            $sourceHash = Get-FileHash -LiteralPath $_.FullName -Algorithm MD5;
            $targetHash = Get-FileHash -LiteralPath $filePath -Algorithm MD5;
            if ($sourceHash.Hash -ne $targetHash.Hash) {
                Write-Host "File hash mismatch: $filePath" -ForegroundColor Yellow;
                $script:hasMismatch = $true;
                $global:mismatches += @{
                    Source = $_.FullName;
                    Target = $filePath;
                    Reason = "Hash mismatch";
                };
            }
        }
    }
}

function CheckFolders {
    param (
        [string]$SourceFolder
    )

    Get-ChildItem -LiteralPath $SourceFolder -Directory | ForEach-Object {
        $global:checkedFolder += 1; ;
        $TargetPath = GetTargetFromSource -SourcePath $_.FullName;
        if (-not (Test-Path -LiteralPath $TargetPath)) {
            Write-Host "Folder not found: Source: $($_.FullName) => Target: $TargetPath" -ForegroundColor Green;
            $script:hasMismatch = $true;
            $script:mismatches += @{
                Source = $_.FullName;
                Target = $TargetPath;
                Reason = "Folder not found";
            };
            return;
        }
        else {
            CheckFolders -SourceFolder $_.FullName;
        }
    }

    CheckFiles -FolderSource $SourceFolder;
}

Write-Host "Results" -ForegroundColor Cyan;
Write-Host "==================" -ForegroundColor Cyan;
Write-Host "Checking folders and files from $Source to $Target";
CheckFolders -SourceFolder $Source;
Write-Host "Checked $global:checkedFolder folders and $global:checkedFiles files.";
Write-Host "==================" -ForegroundColor Cyan;
if ($ReverseCheck) {
    Write-Host "Reversing check from $Target to $Source";
    $Source, $Target = $Target, $Source;
    $global:checkedFolder = 0;
    $global:checkedFiles = 0;
    CheckFolders -SourceFolder $Source;
    Write-Host "Checked $global:checkedFolder folders and $global:checkedFiles files.";
    Write-Host "==================" -ForegroundColor Cyan;
}

if ($Timeout) {
    timeout.exe 10;
}

return @{
    Success        = !$script:hasMismatch;
    CheckedFolders = $global:checkedFolder;
    CheckedFiles   = $global:checkedFiles;
    Mismatches     = $script:mismatches
};