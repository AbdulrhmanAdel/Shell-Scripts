$currentLevel = ""
$finalContent = New-Object System.Text.StringBuilder;
function Display {
    param (
        $info
    )
    
    if ($info -is [System.IO.FileInfo]) {
        $line = "- $currentLevel $($info.Name)" 
        $finalContent.AppendLine($line);
        Write-Host $line -ForegroundColor Green;
        return;
    }

    $line = "# $currentLevel $($info.Name)" 
    $finalContent.AppendLine($line);
    Write-Host $line -ForegroundColor Yellow;
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
Set-Clipboard -Value $finalContent.ToString();
timeout.exe 30;