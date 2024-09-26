Add-Type -AssemblyName Microsoft.VisualBasic

$args | ForEach-Object {
    $info = Get-Item -LiteralPath $_;
    if ($info -is [System.IO.FileInfo]) { 
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($_, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
    else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($_, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
}