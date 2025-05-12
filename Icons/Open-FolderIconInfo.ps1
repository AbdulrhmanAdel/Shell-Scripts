$folderPath = $args[0];
$Options = @(
    @{
        Key   = "Icon"
        Value = "*.ico"
    },
    @{
        Key   = "Desktop.ini"
        Value = "desktop.ini"
    }
)

if (-not (Test-Path -LiteralPath $folderPath)) {
    Exit;
}


$open = Multi-Options-Selector.ps1 -options $Options -Required;
$deskTopAndIco = Get-ChildItem -LiteralPath $folderPath -Include $open -Force;
$deskTopAndIco | ForEach-Object {
    Start-Process -FilePath $_.FullName
}
