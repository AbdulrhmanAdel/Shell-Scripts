Write-Output $args;
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argBuilder = "";
    foreach ($arg in $args) {
        $argBuilder += """$arg"" ";
    }
    Write-Host $argBuilder;
    Start-Process pwsh.exe -Verb RunAs "-File ""$($MyInvocation.MyCommand.Path)"" $($argBuilder)";
    exit;
}

$sourcePath = $args[0];
$sourcePathInfo = Get-Item -LiteralPath $sourcePath;
$linkPath = Read-Host "Enter SymbolicLink Destinition";
Write-Output $linkPath;
New-Item `
    -Path "$linkPath\$($sourcePathInfo.Name)" `
    -Target "$sourcePath" `
    -ItemType SymbolicLink;
    