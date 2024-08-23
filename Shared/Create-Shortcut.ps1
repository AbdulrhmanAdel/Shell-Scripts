. Parse-Args.ps1 $args;

if (!$target -or !$source) {
    Write-Error -Message "Invalid soruce: $soruce -or target: $target"
    Exit;
}

if ((Test-Path -LiteralPath $target) -and $force) {
    Remove-Item -LiteralPath $target -Force;
}

$shell = New-Object -comObject WScript.Shell
$shortcut = $shell.CreateShortcut($target)
$shortcut.TargetPath = $source;
$shortcut.Arguments = """$arguments"""
$shortcut.Save();