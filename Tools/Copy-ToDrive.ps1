[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string[]]
    $Files,
    [Switch]
    $CustomDestiniation,
    [Switch]
    $TeraCopy
)


#region Function

function CopyWithTeraCopy {
    param (
        $source,
        $dest
    )
    $teraCopy = "C:\Program Files\TeraCopy\TeraCopy.exe"
    & $teraCopy  Copy """$source""" """$dest""" /Close;
}

function CopyWithShellGUI {
    param (
        [string[]]$sources,
        [string]$dest
    )

    $shell = New-Object -ComObject "Shell.Application"
    $objFolder = $shell.NameSpace($dest);
    foreach ($source in $sources) {
        $objFolder.CopyHere($source, 88) # 88 => 16, 64, 8
    }

    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
}

function CreateSameHirectyWithDifferentDrive {
    $BasePath = $Files[0];
    $dest = (Split-Path $BasePath).ToCharArray();
    $folderDrive = $dest[0];
    $drives = Get-PSDrive -PSProvider FileSystem | `
        Where-Object { $_.Name -ne $folderDrive } | `
        Foreach-Object { return $_.Name };
    $driveLetter = & Single-Options-Selector.ps1 -Options $drives -MustSelectOne;
    $dest[0] = $driveLetter;
    $dest = $dest -join "";
    if (!(Test-Path -LiteralPath $dest)) {
        New-Item -Path $dest -ItemType Directory -ErrorAction Ignore | Out-Null
    }

    return $dest;
}

#endregion
$outputPath = $CustomDestiniation `
    ? (Folder-Picker.ps1 -IntialDirectory "D:\" -Required) `
    : (CreateSameHirectyWithDifferentDrive);

if ($TeraCopy) {
    CopyWithTeraCopy -source $Files -dest $outputPath;
    Exit;
}

CopyWithShellGUI -sources $Files -dest $outputPath;