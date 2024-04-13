$shell = New-Object -ComObject WScript.Shell

$startMenuPath = "$($env:APPDATA)\Microsoft\Windows\Start Menu\Programs";
Get-ChildItem -LiteralPath $startMenuPath -Include "*.lnk" | ForEach-Object {
    $shortCut = $shell.CreateShortcut($_.FullName);
    $target =  $shortCut.TargetPath.Replace("Education", "Programming")
    $shortCut.TargetPath = $target;
    $shortCut.Save();
};
if ($shell) {
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
}