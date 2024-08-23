$files = $args | Where-Object {
    $_ -match "\.ass|\.srt"
};

$encoding = & Options-Selector.ps1 -options @(
    "ascii",
    "ansi",
    "bigendianunicode",
    "bigendianutf32",
    "oem",
    "unicode",
    "utf7",
    "utf8",
    "utf8BOM",
    "utf8NoBOM",
    "utf32"
) -defaultValue utf8;
$assFiles = @($files | Where-Object { $_.EndsWith(".ass") });
$srtFiles = @($files | Where-Object { $_.EndsWith(".srt") });

if ($assFiles.Length -gt 0) {
    & "$($PSScriptRoot)/Modules/Ass-Editor.ps1" -files $assFiles -encoding $encoding;
}

if ($srtFiles.Length -gt 0) {
    & "$($PSScriptRoot)/Modules/Srt-Editor.ps1" $srtFiles;
}

