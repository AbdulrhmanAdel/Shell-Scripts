$script:DotSourcedCommands = @(
    'Create-Module.ps1'
)

$script:ExcludedCommands = @(
    'Form-Style.ps1'
)

function Get-ShellScriptCommandSource {
    $sharedRoot = "$PSScriptRoot\Shared";
    $shared = Get-ChildItem -Path $sharedRoot -Filter *.ps1 -Recurse -File `
    | Where-Object { $_.FullName.Substring($sharedRoot.Length) -notmatch '\\(Ignore|Modules)\\' } `
    | Where-Object { $_.Name -notin $script:ExcludedCommands } `
    | ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } };

    $tools = @(
        @{ Name = 'Youtube-Downloader.ps1'; Path = "$PSScriptRoot\Youtube\Downloader.ps1" }
    ) | Where-Object { Test-Path -LiteralPath $_.Path };

    return @($shared) + @($tools);
}

$seen = @{};
$exported = @();
foreach ($source in (Get-ShellScriptCommandSource)) {
    if ($seen.ContainsKey($source.Name)) {
        Write-Warning "Duplicate shell script command name: $($source.Name)";
        continue;
    }

    $seen[$source.Name] = $true;
    $operator = $source.Name -in $script:DotSourcedCommands ? '.' : '&';
    $literal = $source.Path -replace "'", "''";
    $body = "$operator '$literal' @args";
    New-Item -Path 'function:' -Name "script:$($source.Name)" -Value ([scriptblock]::Create($body)) | Out-Null;
    $exported += $source.Name;
}

Export-ModuleMember -Function $exported;
