& Run-AsAdmin.ps1 -Arguments ($args | ForEach-Object {return """$_"""});
$takeOwn = "TakeOwn";
foreach ($file in $args) {
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
