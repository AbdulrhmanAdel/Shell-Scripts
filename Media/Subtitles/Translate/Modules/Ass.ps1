$file = $args[0];
$info = Get-Item -LiteralPath $file;
$Parser = Resolve-Path "$PSScriptRoot\..\..\Parser\Ass-Parser.ps1"
$Assembler = Resolve-Path  "$PSScriptRoot\..\..\Parser\Ass-Assembler.ps1"
$Translator = Resolve-Path "$PSScriptRoot\..\Helpers\Subtitles-Translator.ps1"
$parsedResult = & $Parser -File $file --WithStyles;
$content = $parsedResult.Content | ForEach-Object {
    return $_.Content;
}
    
$translation = & $Translator $content;
if (!$translation -or $translation.Length -eq 0) {
    return;
}

$translation = $translation[0];
$currentIndex = 0;
$parsedResult.Content = $parsedResult.Content | ForEach-Object {
    $_.Content = $translation[$currentIndex];
    $currentIndex++;
    return $_;
}

$newPath = $info.Directory.FullName + "/" + $info.Name -replace "$($info.Extension)", ".ar$($info.Extension)";
& $Assembler -Dialogs $parsedResult -outputPath $newPath -encoding "UTF8";
    