if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process Powershell -Verb RunAs "-Command ""$($MyInvocation.MyCommand.Path)""";
    exit;
}

$items = Get-ChildItem -LiteralPath "$($PSScriptRoot)" -File;
$sendToMenuFolder = "$($env:APPDATA)\Microsoft\Windows\SendTo";

Remove-Item -LiteralPath $sendToMenuFolder -Force -Recurse;
if (!(Test-Path -LiteralPath $sendToMenuFolder)) {
    New-Item -Path $sendToMenuFolder -ItemType Directory -Force;
}

foreach ($item in $items) {
    if ($item.Name -eq $MyInvocation.MyCommand.Name) {
        continue;
    }

    Copy-Item `
        -LiteralPath $item.FullName `
        -Destination $sendToMenuFolder -Force;
}