[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Path
)

$file = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue;
if ($file -isnot [System.IO.FileInfo]) {
    Show-Message.ps1 -Message "Not a file: $Path";
    return;
}

$hasExtension = $file.BaseName -and $file.Extension;
$stem = $hasExtension ? $file.BaseName : $file.Name;
$current = $hasExtension ? $file.Extension.TrimStart('.') : '';
$new = "$(Input.ps1 -Title 'Change extension' -Message "New extension for $($file.Name) (without the dot):" -DefaultValue $current)".TrimStart('.');
if (!$new -or $new -eq $current) {
    return;
}

$target = Join-Path $file.DirectoryName "$stem.$new";
if (Test-Path -LiteralPath $target) {
    Show-Message.ps1 -Message "Already exists: $target";
    return;
}

Move-Item -LiteralPath $file.FullName -Destination $target;
