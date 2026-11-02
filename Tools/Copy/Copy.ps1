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
    $Verify,
    [switch]
    $MirrorToDrive,
    [switch]
    $Mirror,
    [string]
    $Handler
)

if ($Mirror) {
    $Handler = $IsWindows ? 'RoboCopy' : 'Rsync';
}

$HandlersPath = "$PSScriptRoot/Handlers/$($IsWindows ? 'Windows' : 'Linux')";
$Handlers = @(Get-ChildItem $HandlersPath -Filter *.psm1 | ForEach-Object BaseName);
if ($Handler -and $Handler -notin $Handlers) {
    throw "Unknown copy handler '$Handler', available: $($Handlers -join ', ')";
}

function Get-SamePathOnOtherDrive {
    $folder = Split-Path $Files[0];
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object Name -ne $folder[0] | ForEach-Object Name;
    $drive = Single-Options-Selector.ps1 -Options $drives -Required;
    $path = $drive + $folder.Substring(1);
    New-Item -Path $path -ItemType Directory -Force | Out-Null;
    return $path;
}

if ($MirrorToDrive) {
    $Destination = Get-SamePathOnOtherDrive;
}
elseif (!$Destination) {
    $Destination = Folder-Picker.ps1 -InitialDirectory ($IsWindows ? "D:\" : $HOME) -Required;
}

if (!$Handler) {
    $Handler = Single-Options-Selector.ps1 -Options $Handlers -Title "Please Select One Copy Mode" -Required;
}

Import-Module "$HandlersPath/$Handler.psm1" -Force;
$options = @{ Files = $Files; Destination = $Destination; Move = $Move; Verify = $Verify };
if ($Mirror) {
    $options.Mirror = $true;
}
Invoke-Copy @options;
Read-Host "Press Any Key To Exit.";
