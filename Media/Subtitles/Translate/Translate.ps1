$ParserAndAssembler = @{
    ".srt" = @{
        "Parser"    = "D:\Programming\Projects\Personal Projects\Shell-Scripts\Media\Subtitles\Parser\Srt-Parser.ps1"
        "Assembler" = "D:\Programming\Projects\Personal Projects\Shell-Scripts\Media\Subtitles\Parser\Srt-Assembler.ps1"
    }
}

$files = $args | Where-Object { & Is-Subtitle $_ };
$files | ForEach-Object {
    $info = Get-Item -LiteralPath $_;
    Write-Host "=====================================";
    Write-Host "Handling File $($info.Name)" -ForegroundColor Green;
    $handler = $ParserAndAssembler[$info.Extension];
    $parsedResult = & $handler["Parser"] $_;
    $content = $parsedResult | ForEach-Object {
        return $_.Content[0..($_.Content.Length - 2)]
    }
    
    $translation = & "$PSScriptRoot\Helpers\Subtitles-Translator.ps1" $content;
    if (!$translation -or $translation.Length -eq 0) {
        Exit;
    }

    $translation = $translation[0];
    $currentIndex = 0;
    $newContent = $parsedResult | ForEach-Object {
        for ($i = 0; $i -lt $_.Content.Count - 1; $i++) {
            $_.Content[$i] = $translation[$currentIndex];
            $currentIndex++;
        }

        return $_;
    }

    $newPath = $info.Directory.FullName + "/" + $info.Name -replace "$($info.Extension)", ".ar$($info.Extension)";
    & $handler["Assembler"] -Dialogs $newContent -outputPath $newPath;
    Write-Host "=====================================";
    Write-Host "";
    Start-Sleep -Seconds 1;
}

