[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('Path', 'Folder', 'Name', 'Stem')]
    [string]$Mode,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
)

if (!$Paths) {
    return;
}

$lines = foreach ($path in $Paths) {
    $fullPath = [System.IO.Path]::GetFullPath($path);
    $name = Split-Path $fullPath -Leaf;
    switch ($Mode) {
        'Path' { $fullPath }
        'Folder' { Split-Path $fullPath -Parent }
        'Name' { $name }
        'Stem' { $name -replace '(?<=.)\.[^.]*$' }
    }
}

Copy-ToClipboard.ps1 -Text (($lines | Select-Object -Unique) -join "`n");
