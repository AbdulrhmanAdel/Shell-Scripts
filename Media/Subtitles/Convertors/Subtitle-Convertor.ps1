# & Parse-Args.ps1 $args;
$modules = @{
    ".ass" = "$($PSScriptRoot)/Modules/Ass-To-Srt.ps1";
    ".srt" = "$($PSScriptRoot)/Modules/Srt-To-Ass.ps1";
}

$args | Group-Object {
    return [System.IO.Path]::GetExtension($_);
} | ForEach-Object {
    $extension = $_.Name;
    $module = $modules[$extension];
    if ($module) {
        & $module $_.Group $encoding;
    }
    else {
        Write-Host "UnSupported Extension: $extension" -ForegroundColor Red;
    }
}
