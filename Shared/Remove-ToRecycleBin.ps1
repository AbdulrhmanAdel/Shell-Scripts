[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Paths
)

Add-Type -AssemblyName Microsoft.VisualBasic

$Paths | ForEach-Object {
    # [System.IO.Path]::
    $info = Get-Item -LiteralPath $_;
    Write-Host "Moving $_ TO RycleBin" -ForegroundColor Red;
    if ($info -is [System.IO.FileInfo]) { 
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($_, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
    else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($_, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
}