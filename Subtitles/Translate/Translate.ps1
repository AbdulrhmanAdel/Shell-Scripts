[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$ParserAndAssembler = @{
    ".srt" = "$PSScriptRoot\Modules\Srt.ps1"
    ".ass" = "$PSScriptRoot\Modules\Ass.ps1"
}

$Files | Where-Object { & Is-Subtitle $_ } | ForEach-Object {
    Write-Host "=====================================";
    $fileName = [System.IO.Path]::GetFileName($_);
    $extension = [System.IO.Path]::GetExtension($_);
    Write-Host "Handling File $fileName" -ForegroundColor Green;
    $handler = $ParserAndAssembler[$extension];
    & $handler $_;
    Write-Host "====================================="
    Start-Sleep -Seconds 1;
}

