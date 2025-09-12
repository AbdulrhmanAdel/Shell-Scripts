[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

$Files | Foreach-Object {
    $filePath = $_;
    $fileInfo = Get-Item -LiteralPath $filePath;
    $shortcutName = $fileInfo.Name.Replace($fileInfo.Extension, ".lnk");
    $startmenuPath = "$($env:APPDATA)\Microsoft\Windows\Start Menu\Programs";

    if ($fileInfo.Extension -in (".bat", ".ps1")) {
        if ($fileInfo.Name -match "Update") {
            $startmenuPath += "\Updaters";
        }
        else {
            $startmenuPath += "\Scripts";
        }
        
    }

    if (!(Test-Path -LiteralPath $startmenuPath)) {
        New-Item -Path $startmenuPath -ItemType Directory -Force;
    }

    $ShortcutPath = "$startmenuPath\$shortcutName";
    if (Test-Path -LiteralPath $ShortcutPath) {
        Remove-Item -LiteralPath $ShortcutPath;
    }
    $WshShell = New-Object -comObject "WScript.Shell";
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $filePath;
    $Shortcut.Save();
}
