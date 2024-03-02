$items = Get-ChildItem -LiteralPath "$($PSScriptRoot)" -File;

foreach ($item in $items) {
    if ($item.Name -eq $MyInvocation.MyCommand.Name) {
        continue;
    }

    Copy-Item `
        -LiteralPath $item.FullName `
        -Destination "$($env:APPDATA)\Microsoft\Windows\SendTo" -Force;
}
timeout.exe 5;