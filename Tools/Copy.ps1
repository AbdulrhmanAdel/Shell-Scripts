[CmdletBinding()]
param (
    [string]
    $Destination,
    [switch]
    $Move,
    [switch]
    $MirrorToDrive,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

#Region Helpers 
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

function CreateSameHierarchyWithDifferentDrive {
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

#EndRegion

$global:outputPath = $null;

if ($MirrorToDrive) {
    $global:outputPath = CreateSameHierarchyWithDifferentDrive;
}
elseif (!$Destination) {
    $global:outputPath = Folder-Picker.ps1 -InitialDirectory "D:\" -Required
}
$Handlers = @(
    @{
        Key     = 'Explorer'
        Handler = {
            CopyWithShellGUI -sources $Files -dest $global:outputPath;
        }
    }
    @{
        Key     = 'RoboCopy'
        Handler = {
            foreach ($file in $Files) {
                $finalOutput = $global:outputPath;
                $info = Get-Item -LiteralPath $file
                if ($info -is [System.IO.DirectoryInfo]) {
                    $finalOutput += "\$($info.Name)";
                }
                $process = Start-Process robocopy -ArgumentList @(
                    """$file""", """$finalOutput"""
                    "/MIR", "/R:0", 
                    # "/COPYALL", "/DCOPY:DAT", "/B", 
                    "/XD", '$Recycle.bin', """system volume information"""
                    "/xf", 'thumbs.db',
                    "/mt:10"
                    "/np"
                ) -Wait -PassThru -NoNewWindow;

                if ($process.ExitCode -eq 1 -and $Move) {
                    Remove-Item -LiteralPath $file -Recurse -Force;
                }
            }
        }
    }
);

$mode = Single-Options-Selector.ps1 -Options $Handlers -Title "PLease Select One Copy Mode" -MustSelectOne;
$mode.Handler.Invoke();
timeout.exe 15;