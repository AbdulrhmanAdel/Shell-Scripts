$files = $args | Where-Object {
    $_ -match "\.ass|\.srt"
};

$assFiles = @($files | Where-Object { $_.EndsWith(".ass") });
$srtFiles = @($files | Where-Object { $_.EndsWith(".srt") });

if ($assFiles.Length -gt 0) {
    & "$($PSScriptRoot)/Modules/Ass-Editor.ps1" -files $assFiles -encoding $encoding;
}

if ($srtFiles.Length -gt 0) {
    & "$($PSScriptRoot)/Modules/Srt-Editor.ps1" $srtFiles;
}

