[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]
    $Source,
    [Parameter(Mandatory, Position = 1)]
    [string]
    $Target,
    [switch]
    $CheckHashes,
    [switch]
    $ReverseCheck
)

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
        }

        if ($CheckHashes) {
            $sourceHash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256;
            $targetHash = Get-FileHash -LiteralPath $filePath -Algorithm SHA256;
            if ($sourceHash.Hash -ne $targetHash.Hash) {
                Write-Host "File hash mismatch: $filePath" -ForegroundColor Yellow;
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

timeout.exe 10;