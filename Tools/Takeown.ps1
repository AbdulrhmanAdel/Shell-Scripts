& Run-AsAdmin.ps1 $args;

$files = $args;
$takeOwn = "TakeOwn";
foreach ($file in $files) {
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

timeout.exe 5;
