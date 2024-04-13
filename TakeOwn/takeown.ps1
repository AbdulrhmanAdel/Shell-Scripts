if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argBuilder = "";
    foreach ($arg in $args) {
        $argBuilder += """$arg"" ";
    }
    Write-Host $argBuilder;
    Start-Process pwsh.exe -Verb RunAs "-File ""$($MyInvocation.MyCommand.Path)"" $($argBuilder)";
    exit;
}

$files = $args;
$takeOwn = "TakeOwn";
foreach ($file in $files) {
    $fileInfo = Get-Item -LiteralPath $file;
    if ($fileInfo -is [System.IO.FileInfo]) {
        &$takeOwn /f "$file"
    }
    else {
        $gitPath = "$file\.git";
        if (Test-Path -LiteralPath $gitPath) {
            &$takeOwn /f "$file"
            $file = $gitPath;
        }
        &$takeOwn /f "$file" /r /d y
    }
    Write-Output "TakeDown finished for $file"
}

foreach ($file in $files) {
    Write-Output "$file";
}

timeout.exe 5;
