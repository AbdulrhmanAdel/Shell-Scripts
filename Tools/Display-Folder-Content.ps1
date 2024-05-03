$currentLevel = ""
function Display {
    param (
        $info
    )
    
    if ($info -is [System.IO.FileInfo]) {
        Write-Host "- $currentLevel $($info.Name)" -ForegroundColor Green;
        return;
    }

    Write-Host "# $currentLevel $($info.Name)" -ForegroundColor Yellow;
    $currentLevel += "    ";
    Get-ChildItem -LiteralPath $info.FullName -File | ForEach-Object {
        Display -info $_;
    };

    Get-ChildItem -LiteralPath $info.FullName -Directory | ForEach-Object {
        Display -info $_;
    };
}
$info = Get-Item -LiteralPath $args[0];
Display -info $info;

timeout.exe 30;