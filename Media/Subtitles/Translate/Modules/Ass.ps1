$file = $args[0];
$info = Get-Item -LiteralPath $file;
$Translator = Resolve-Path "$PSScriptRoot\..\Helpers\Subtitles-Translator.ps1"
$parsedResult = & Ass-Parser.ps1 -File $file -WithStyles;
$content = $parsedResult.Content | ForEach-Object {
    return $_.Content;
}
    
$translations = & $Translator $content;
if ($translations.Length -eq 0) {
    Write-Host "No Translation Found." -ForegroundColor Red;
    return;
}

$currentIndex = 0;
$parsedResult.Content = $parsedResult.Content | ForEach-Object {
    $_.Content = $translations[$currentIndex];
    $currentIndex++;
    return $_;
}

$newPath = $info.Directory.FullName + "/" + $info.Name -replace "$($info.Extension)", ".ar$($info.Extension)";
& Ass-Assembler.ps1 -Dialogs $parsedResult -OutputPath $newPath -Encoding "UTF8";
    