#region External Programs
$mkvMerge = "D:\Programs\Media\Tools\mkvtoolnix\mkvmerge.exe";
$mkvextract = "D:\Programs\Media\Tools\mkvtoolnix\mkvextract.exe";
#endregion

$colors = @(
    #region Vars
    [System.ConsoleColor]::Black,
    [System.ConsoleColor]::DarkBlue,
    [System.ConsoleColor]::DarkGreen,
    [System.ConsoleColor]::DarkCyan,
    [System.ConsoleColor]::DarkMagenta,
    [System.ConsoleColor]::DarkYellow,
    [System.ConsoleColor]::Gray,
    [System.ConsoleColor]::DarkGray,
    [System.ConsoleColor]::Blue,
    [System.ConsoleColor]::Green,
    [System.ConsoleColor]::Cyan,
    [System.ConsoleColor]::Magenta
);

#endregion
@($args | Where-Object { $_ -match ".*\.mkv$"; }) | ForEach-Object {
    $file = $_;
    $color = Get-Random $colors;
    Write-Host "Start Handling File: $file" -ForegroundColor $color;
    $fileInfo = Get-Item -LiteralPath $file;
    $chapterFileName = "$($fileInfo.Name)-$(Get-Random)_chapters.xml";
    $chapterOutput = "$($env:TEMP)\$chapterFileName";
    & $mkvextract chapters $_ > $chapterOutput;

    # Backup Chapters File
    $chaptersDirectory = $fileInfo.Directory.FullName + "\Chapters";
    if (!(Test-Path -LiteralPath $chaptersDirectory)) {
        New-Item -ItemType Directory -Path $chaptersDirectory;
    }
    Copy-Item -LiteralPath $chapterOutput -Destination "$chaptersDirectory/$chapterFileName" -Force;


    [xml]$xml = Get-Content $chapterOutput;
    $editionEntry = $xml.GetElementsByTagName("EditionEntry").Item(0);
    $final = $editionEntry.ChildNodes | ForEach-Object {
        $tag = $_;
        switch ($tag.Name) {
            "EditionFlagOrdered" {
                $tag.InnerText = "0";
                return $tag;
            }
            "ChapterAtom" {
                $segemnts = $tag.GetElementsByTagName("ChapterSegmentUID");
                if (!$segemnts.Count) {
                    return $tag;
                }
                break;
            }
            Default {
                return $tag;
            }
        }
    }
    $editionEntry.RemoveAll();
    $final | ForEach-Object {
        $editionEntry.AppendChild($_) | Out-Null
    }
    $xml.OuterXml | Set-Content $chapterOutput;
    $tempFileName = "$($fileInfo.Directory.FullName)\" + $fileInfo.Name -replace $fileInfo.Extension, "(TEMP)$($fileInfo.Extension)";
    Rename-Item -LiteralPath $file -NewName $tempFileName -Force;
    & $mkvmerge -o "$file" --chapters "$chapterOutput" --no-chapters "$tempFileName";
    Remove-Item -LiteralPath $chapterOutput -Force;
    Remove-Item -LiteralPath $tempFileName -Force;
    Write-Host "Done Handling File: $file" -ForegroundColor $color;
}

timeout 15;