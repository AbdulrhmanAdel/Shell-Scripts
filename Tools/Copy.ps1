[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files,
    [string]
    $Destination,
    [switch]
    $Move,
    [switch]
    $MirrorToDrive,
    [ValidateSet('Explorer', 'FastCopy', 'RoboCopy')]
    $Handler
)

Write-Host "Files $Files Destination $Destination Move $Move Verify $Verify MirrorToDrive $MirrorToDrive Handler $Handler";

function Verify {
    param (
        $Source,
        $Target
    )

    return & "$PSScriptRoot\Check-FolderSync.ps1" -Source $Source `
        -Target $Target `
        -CheckHashes $true;
}

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

        if ($Verify) {
            $SourceName = Split-Path -Leaf $source;
            $target = "$dest\$SourceName";
            Verify -Source $source -Target $target;
        }
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
    $driveLetter = & Single-Options-Selector.ps1 -Options $drives -Required;
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
else {
    $global:outputPath = $Destination;
}

$Handlers = @(
    @{
        Key     = 'Explorer'
        Handler = {
            CopyWithShellGUI -sources $Files -dest $global:outputPath;
        }
    }
    @{
        Key     = 'FastCopy'
        Handler = {
            $processArguments = @(
                "/cmd=$($Move ? "move" : "diff")",
                "/estimate", "/balloon",
                "/force_close", "/open_window"
            );
            if ($Verify) {
                $processArguments += @("/verify", "/verifyinfo")
            }

            $ProcessArguments += $Files + @(
                "/to=`"$global:outputPath`""
            )
            $fastCopyProcess = Start-Process fastcopy.exe -ArgumentList $processArguments -Wait -PassThru;
            if ($fastCopyProcess.ExitCode -eq 0) {
                Write-Host "FastCopy completed successfully." -ForegroundColor Green;
            }
            else {
                Write-Host "FastCopy failed with exit code $($fastCopyProcess.ExitCode)." -ForegroundColor Red;
            }
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
                    "/mt:16"
                    # "/np"
                    # "/NFL", "/NDL"
                    "/V", "/ETA"
                ) -Wait -PassThru -NoNewWindow;

                if ($process.ExitCode -eq 1 -and $Move) {
                    if (Verify -Source $file -Target $finalOutput) {
                        Remove-Item -LiteralPath $file -Recurse -Force;
                    }
                    return;
                }
                if ($Verify) {
                    $verifyResult = Verify -Source $file -Target $finalOutput;
                    Write-Host "Verification result for $($file): $($verifyResult.Success)" -ForegroundColor Yellow;
                }
            }
        }
    }
);


$mode = $null
if ($Handler) {
    $mode = $Handlers | Where-Object { $_.Key -eq $Handler } | Select-Object -First 1;
}
else {
    $mode = Single-Options-Selector.ps1 -Options $Handlers -Title "PLease Select One Copy Mode" -Required;
}
$mode.Handler.Invoke();
Read-Host "Press Any Key To Exit."
