$files = $args;


$objShell = New-Object -ComObject "Shell.Application"
function CopyWithGui {
    param (
        $source,
        $dest
    )

    $objFolder = $objShell.NameSpace($dest) 
    $objFolder.CopyHere($source, 16)
}

$driveLetter = Read-Host "Enter Driver Letter";
$files | ForEach-Object {
    $path = "$($driveLetter):\"
    $newPath = $_;
    $pathes = $newPath -split "\\";
    for ($i = 1; $i -lt $pathes.Count; $i++) {
        if ($i -eq $pathes.Count - 1) {
            CopyWithGui -source $_ -dest $path;
            return;
        }
        
        $path += $pathes[$i] + "\";
        if (Test-Path -LiteralPath $path) {
            continue;
        }

        New-Item -Path $path -ItemType Directory -Force;
    }
}