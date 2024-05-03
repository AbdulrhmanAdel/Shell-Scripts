$folderPath = $args[0].ToString().ToLower();
$path = [Environment]::GetEnvironmentVariable('path', [EnvironmentVariableTarget]::User);
$pathes = $path -split ";";
$alreadyExists = $pathes.Contains($folderPath);
if ($alreadyExists) {
    Write-Host "Path Already Exists" -ForegroundColor Red
    timeout.exe 5;
    Exit;
}


Write-Host "Deleted Pathes:" -ForegroundColor Red;
$pathes = $pathes | Foreach-Object { 
    $isExists = Test-Path -LiteralPath $_ 
    if ($isExists) {
        return $_;
    }

    Write-Host $_  -ForegroundColor Red;
};

Write-Host "====================" -ForegroundColor Green;
$pathes += "$folderPath";
Write-Host "New Pathes:" -ForegroundColor Green;
$pathes | Foreach-Object { Write-Host $_ -ForegroundColor Green; }
$path = $pathes -join ";";
[Environment]::SetEnvironmentVariable('Path', $path, [EnvironmentVariableTarget]::User);
timeout.exe 10;