$files = $args;


#region functions
$teraCopy = "C:\Program Files\TeraCopy\TeraCopy.exe"
# $shell = New-Object -ComObject "Shell.Application"
function CopyWithTeraCopy {
    param (
        $source,
        $dest
    )

    & $teraCopy  Copy """$source""" """$dest""" /Close;
}

$shell = New-Object -ComObject "Shell.Application"
function CopyWithShellGUI {
    param (
        $source,
        $dest
    )

    $objFolder = $shell.NameSpace($dest) 
    $objFolder.CopyHere($source, 16)
}

#endregion
$driveLetter = Read-Host "Enter Driver Letter";
$files | ForEach-Object {
    $path = "$($driveLetter):"
    $newPath = $_;
    $pathes = $newPath -split "\\";
    for ($i = 1; $i -lt $pathes.Count; $i++) {
        if ($i -eq $pathes.Count - 1) {
            CopyWithShellGUI -source $_ -dest $path;
            return;
        }
        
        $path += "\$($pathes[$i])";
        if (Test-Path -LiteralPath $path) {
            continue;
        }

        New-Item -Path $path -ItemType Directory -Force;
    }
}

if ($shell) {
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
}