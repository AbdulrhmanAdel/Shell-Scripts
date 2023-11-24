$folders = Get-ChildItem -LiteralPath "D:\New folder\AtomicHeart\Content\Localization" -Recurse;

foreach ($folder in $folders) {
    if ($folder.Name -eq "en" -or $folder.Name -eq "en-US") {
        Rename-Item -LiteralPath $folder.FullName "it-IT";
    }
}