$method = & Options-Selector.ps1 `
    -options @("Series", "Movies") -defaultValue "Series" `
    -title "Rename Source";

if (!$method) { EXIT; }

& "$($PSScriptRoot)/modules/Subtitle-Renamer-$method" $args;
