$ParserAndAssembler = @{
    ".srt" = "$PSScriptRoot\Modules\Srt.ps1"
    ".ass" = "$PSScriptRoot\Modules\Ass.ps1"
}

. Parse-Args.ps1 $args;
$files = $args | Where-Object { & Is-Subtitle $_ };
$files | ForEach-Object {
    Write-Host "=====================================";
    $fileName = [System.IO.Path]::GetFileName($_);
    $extension = [System.IO.Path]::GetExtension($_);
    Write-Host "Handling File $fileName" -ForegroundColor Green;
    $handler = $ParserAndAssembler[$extension];
    & $handler $_;
    Write-Host "====================================="
    Start-Sleep -Seconds 1;
}

