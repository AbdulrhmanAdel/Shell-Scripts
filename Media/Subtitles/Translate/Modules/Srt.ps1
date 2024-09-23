$file = $args[0];
$info = Get-Item -LiteralPath $file;

$Parser = Resolve-Path "$PSScriptRoot\..\..\Parser\Srt-Parser.ps1"
$Assembler = Resolve-Path  "$PSScriptRoot\..\..\Parser\Srt-Assembler.ps1"
$Translator = Resolve-Path "$PSScriptRoot\..\Helpers\Subtitles-Translator.ps1"
$parsedResult = & $Parser -File $file;
$content = $parsedResult | ForEach-Object {
    return $_.Content[0..($_.Content.Length - 2)]
}
    
    
$translations = & $Translator $content;
if ($translations.Length -eq 0) {
    Write-Host "No Translation Found." -ForegroundColor Red;
    return;
}

$currentIndex = 0;
$newContent = $parsedResult | ForEach-Object {
    for ($i = 0; $i -lt $_.Content.Count - 1; $i++) {
        $_.Content[$i] = $translations[$currentIndex];
        $currentIndex++;
    }

    return $_;
}

$newPath = $info.Directory.FullName + "/" + $info.Name -replace "$($info.Extension)", ".ar$($info.Extension)";
& $Assembler -Dialogs $newContent -outputPath $newPath -encoding "UTF8";
    