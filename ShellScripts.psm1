$script:ModuleGuid = '8f3a6d21-4c7b-4f5e-9a02-6d1b8e4c7a93';
$script:ManifestPath = "$PSScriptRoot\ShellScripts.psd1";

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

function Update-ShellScriptsManifest {
    [CmdletBinding()]
    param()

    New-ModuleManifest -Path $script:ManifestPath `
        -RootModule 'ShellScripts.psm1' `
        -ModuleVersion '1.0.0' `
        -Guid $script:ModuleGuid `
        -Description 'Shared commands for the Shell-Scripts repository.' `
        -PowerShellVersion '7.0' `
        -FunctionsToExport $script:ShellScriptCommands `
        -CmdletsToExport @() `
        -VariablesToExport @() `
        -AliasesToExport @();

    return $script:ShellScriptCommands;
}

$seen = @{};
$discovered = @();
foreach ($source in (Get-ShellScriptCommandSource)) {
    if ($seen.ContainsKey($source.Name)) {
        Write-Warning "Duplicate shell script command name: $($source.Name)";
        continue;
    }

    $seen[$source.Name] = $true;
    $operator = $source.Name -in $script:DotSourcedCommands ? '.' : '&';
    $literal = $source.Path -replace "'", "''";
    New-Item -Path 'function:' -Name "script:$($source.Name)" -Value ([scriptblock]::Create("$operator '$literal' @args")) | Out-Null;
    $discovered += $source.Name;
}

$script:ShellScriptCommands = @(@($discovered) + 'Update-ShellScriptsManifest' | Sort-Object);

$published = @();
if (Test-Path -LiteralPath $script:ManifestPath) {
    try {
        $published = @((Import-PowerShellDataFile -LiteralPath $script:ManifestPath).FunctionsToExport);
    }
    catch {
        $published = @();
    }
}

if (Compare-Object -ReferenceObject $published -DifferenceObject $script:ShellScriptCommands) {
    try {
        Update-ShellScriptsManifest | Out-Null;
        Write-Warning "ShellScripts manifest refreshed, new commands are available in the next session.";
    }
    catch {
        Write-Warning "Could not refresh the ShellScripts manifest: $($_.Exception.Message)";
    }
}

Export-ModuleMember -Function $script:ShellScriptCommands;
